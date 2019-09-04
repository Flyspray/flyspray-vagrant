# Example for Testing Flyspray with LDAP

## Demo only for development!

Uses complete insecure settings just vor development purposes.

#### Mysql (mariadb-server)

```
user: flyspray
password: flyspray

```
But also passwordless possible on commandline with 

```
vagrant ssh 
sudo mysql
```

#### LDAP (slapd)
users: alice, bob, ..., henry
user passwords: password (for all demo users)

## INSTALL

### Prerequisite

- install virtualbox (maybe also vmware or qemu works, but I use virtualbox)
- install vagrant

- You can also install the vagrant plugin hostsupdater if you want.
That automates setting the ldap.example.com into your /etc/hosts and removes it when the virtual machine is destroyed (vagrant destroy)

### Installation
``` bash
cd ldapflyspraytest
wget https://raw.githubusercontent.com/Flyspray/flyspray-vagrant/master/ldap/Vagrantfile
wget https://raw.githubusercontent.com/Flyspray/flyspray-vagrant/master/ldap/provision.sh
vagrant up
```

When `vagrant up` finishes, there should also some instructions shown at the end.

You should now be able to access http://ldap.example.com/fsm/ from your web browser and follow the webinstaller setup instructions there.

And you can login with `vagrant ssh` into the machine.

Flyspray installed at /var/www/html/fsm/ , so flyspray.conf.php is at
/var/www/html/fsm/flyspray.conf.php after following webinstaller setup instructions.

