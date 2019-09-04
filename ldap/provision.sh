#!/bin/bash
set -eux

apt-get install -y unzip curl mariadb-server apache2
apt-get install -y php php-gd php-mysql php-ldap php-xml php-curl

mysql -e 'CREATE DATABASE flyspray DEFAULT CHARSET=utf8mb4'
mysql -e "CREATE USER flyspray@localhost IDENTIFIED BY 'flyspray'"
mysql -e "GRANT ALL PRIVILEGES ON flyspray.* TO 'flyspray'@'localhost'"

systemctl restart apache2

config_organization_name=Example
# ou organisationalUnit
config_ou='users'
config_domain=$(hostname --domain)
config_domain_dc="dc=$(echo $config_domain | sed 's/\./,dc=/g')"
config_admin_dn="cn=admin,$config_domain_dc"
config_admin_password=password

# handled by vagrant plugin hostsupdater
#config_fqdn=$(hostname --fqdn)
#echo "127.0.0.1 $config_fqdn" >>/etc/hosts

# these anwsers were obtained (after installing slapd) with:
#
#   #sudo debconf-show slapd
#   sudo apt-get install debconf-utils
#   # this way you can see the comments:
#   sudo debconf-get-selections
#   # this way you can just see the values needed for debconf-set-selections:
#   sudo debconf-get-selections | grep -E '^slapd\s+' | sort
debconf-set-selections <<EOF
slapd slapd/password1 password $config_admin_password
slapd slapd/password2 password $config_admin_password
slapd slapd/domain string $config_domain
slapd shared/organization string $config_organization_name
EOF

apt-get install -y --no-install-recommends slapd ldap-utils

# create the users container
# NB the `cn=admin,$config_domain_dc` user was automatically created
#    when the slapd package was installed.
ldapadd -D $config_admin_dn -w $config_admin_password <<EOF
dn: ou=$config_ou,$config_domain_dc
objectClass: organizationalUnit
ou: $config_ou
EOF

# add user
function add_person {
    local n=$1; shift
    local name=$1; shift
    ldapadd -D $config_admin_dn -w $config_admin_password <<EOF
dn: uid=$name,ou=$config_ou,$config_domain_dc
objectClass: inetOrgPerson
userPassword: $(slappasswd -s password)
uid: $name
mail: $name@$config_domain
cn: $name doe
givenName: $name
sn: doe
#telephoneNumber: +1 888 555 000$((n+1))
#jpegPhoto::$(base64 -w 66 /vagrant/avatars/avatar-$n.jpg | sed 's,^, ,g')
#labeledURI: http://example.com/~$name Personal Home Page
EOF
}

people=(alice bob carol dave eve frank grace henry)
for n in "${!people[@]}"; do
    add_person $n "${people[$n]}"
done

cd /var/www/html
curl -sL https://github.com/Flyspray/flyspray/archive/master.zip -o master.zip
unzip -q master.zip
mv flyspray-master fsm
chown -R www-data.www-data *
cd /var/www/html/fsm
curl -sS https://getcomposer.org/installer | php
# This might require some personal github token when some download limit from github are reached.
php composer.phar install
chown -R www-data.www-data *

# show the configuration tree
ldapsearch -Q -LLL -Y EXTERNAL -H ldapi:/// -b cn=config dn | grep -v '^$'

# show the data tree
ldapsearch -x -LLL -b $config_domain_dc dn | grep -v '^$'

# search for people and print some of their attributes
ldapsearch -x -LLL -b $config_domain_dc '(objectClass=person)' cn mail

echo "1. Enter http://"$(hostname -f)"/fsm/ in your web browser and complete setup instructions"
echo '2. Then edit flyspray.conf.php: in [general] add auth_method=ldap and add a section
[ldap]
uri="ldap://example.com:389"
base_dn="ou=users,dc=example,dc=com"
search_user="cn=admin,dc=example,dc=com"
search_pass="password"
filter="uid=%USERNAME%"
'
