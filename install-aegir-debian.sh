#! /bin/bash
#
# Aegir 2.x install script for Debian Wheezy
# (install-aegir-on-debian.sh)
# on Github: https://github.com/doka/install-aegir-on-debian
#
# This script assumes:
# - your hostname is: myhost.local (it will be the Aegir admin interface)
# - your IP address is: 192.168.1.101
# - your hostname has to be a full qualified domain name (FQDN)
#
# Prerequisites:
# - you run this script on a bare debian server, only extra is OpenSSH server
# - you run this script with a user having root rights
#
# - you have set static IP address in /etc/network/interfaces like this:
# auto eth0
# iface eth0 inet static
# address 192.168.1.101
# network 192.168.1.0
# netmask 255.255.255.0
# gateway 192.168.1.1
#
# - you have set static IP address in /etc/hostname:
# myhost.local
#
# - you have set /etc/hosts
# 192.168.2.101 myhost.local myhost
#
# - reboot your server after these changes!
#
# - dowload this script to the server and make it executable
# wget https://raw.github.com/doka/install-aegir-on-debian/master/install-aegir-on-debian.sh
# chmod 750 ./install-aegir-on-debian.sh
#
#
# ***********************************
# set versions Aegir & Drush versions
DRUSH_VERSION="6.4.0"
# see: https://github.com/drush-ops/drush/releases
#
AEGIR_VERSION="6.x-2.1"
#
# ***********************************
#
#
# 1. install software requirements for Aegir, on a bare Debian Wheezy server.
#    Set the root password for MySQL
#    Accept the defaults at postfix install (Internet site, ...)
#
apt-get -y update && apt-get -y upgrade
apt-get -y install apache2 php5 php5-cli php5-gd php5-mysql php-pear postfix sudo rsync git-core unzip mysql-server
#
#
# 2. LAMP configurations
#
# PHP: set higher memory limits
sed -i 's/memory_limit = -1/memory_limit = 192M/' /etc/php5/cli/php.ini
sed -i 's/memory_limit = 128M/memory_limit = 192M/' /etc/php5/apache2/php.ini
#
# Apache
a2enmod rewrite
ln -s /var/aegir/config/apache.conf /etc/apache2/conf.d/aegir.conf
#
# MySQL: enable all IP addresses to bind
sed -i 's/bind-address/#bind-address/' /etc/mysql/my.cnf
service mysql restart
# MySQL: using secure install script instead
mysql_secure_installation
#
#
# 3. Aegir install
#
# add Aegir user
adduser --system --group --home /var/aegir aegir
adduser aegir www-data
#
# sudo rights for the Aegir user to restart Apache
echo 'aegir ALL=NOPASSWD: /usr/sbin/apache2ctl' | tee /tmp/aegir
chmod 0440 /tmp/aegir
cp /tmp/aegir /etc/sudoers.d/aegir
#
#
# add public key to aegir user?
#
# generate SSH keys for the aegir user
# su -s /bin/sh - aegir -c "ssh-keygen -t rsa"
#
# Drush install
#
wget https://github.com/drush-ops/drush/archive/$DRUSH_VERSION.tar.gz
gunzip -c $DRUSH_VERSION.tar.gz | tar -xf -
mv drush-$DRUSH_VERSION /usr/local/src/
rm $DRUSH_VERSION.tar.gz
chmod u+x /usr/local/src/drush-$DRUSH_VERSION/drush
ln -s /usr/local/src/drush-$DRUSH_VERSION/drush /usr/local/bin/drush
# Drush needs to download  Console_Table from PHP
wget http://download.pear.php.net/package/Console_Table-1.1.3.tgz
gunzip -c Console_Table-1.1.3.tgz | tar -xf -
mv Console_Table-1.1.3 /usr/local/src/drush-6.4.0/lib/
rm Console_Table-1.1.3.tgz
# check
which drush
#
# install provision backend by drush
echo "installing provision backend ..."
su -s /bin/sh - aegir -c "drush dl --destination=/var/aegir/.drush provision-$AEGIR_VERSION"
su -s /bin/sh - aegir -c "drush cache-clear drush"
#
# install hostmaster frontend by drush
echo "installing frontend: Drupal with hostmaster profile ..."
su -s /bin/sh - aegir -c "drush hostmaster-install"

# install Hosting Queue Daemon
# see: http://community.aegirproject.org/installing/manual#Install_the_Hosting_Queue_Daemon
# echo "installing Hosting Queue Daemon ..."
# cp /var/aegir/profiles/hostmaster/modules/hosting/queued/init.d.example /etc/init.d/hosting-queued
# update-rc.d hosting-queued defaults
# /etc/init.d/hosting-queued

echo "
#
# Checkpoint / But not yet finished!
#
# The installation has provided you with a one-time login URL to stdout
# (see above), or via an e-mail. Use this link to login to your new Aegir site
# for the first time.
#
# 1. Do not forget to add all the domains you are going to manage by Aegir,
# to your /etc/hosts files on every boxes your are using!
#
# 2. Copy your public id to remote servers, if you use any remote servers:
# ssh-copy-id <myhost.local>
# ssh <myhost.local>
#
# 3. You can switch to the aegir user by:
# sudo su -s /bin/bash - aegir
#
"
