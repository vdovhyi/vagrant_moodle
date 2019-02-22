#!/bin/bash
sudo yum update -y 
sudo yum install -y httpd
sudo systemctl start httpd.service
sudo systemctl enable httpd.service

#php
sudo yum install -y epel-release
sudo rpm -Uhv https://rpms.remirepo.net/enterprise/remi-release-7.rpm
sudo yum-config-manager --enable remi-php71
sudo yum install -y php php-common php-intl php-zip php-soap php-xmlrpc php-opcache php-mbstring php-gd php-curl php-mysql php-xml

#wget, expect
sudo yum install -y wget.x86_64
sudo yum install -y expect

# MySQL
sudo wget http://dev.mysql.com/get/mysql57-community-release-el7-7.noarch.rpm
sudo yum -y install ./mysql57-community-release-el7-7.noarch.rpm
sudo yum -y install mysql-community-server
sudo systemctl start mysqld 

MYSQL_SERVICE=mysqld
MYSQL_LOG_FILE=/var/log/${MYSQL_SERVICE}.log
MYSQL_PWD=$(grep -oP '(?<=A temporary password is generated for root@localhost: )[^ ]+' ${MYSQL_LOG_FILE})

MYSQL_UPDATE=$(expect -c "
set timeout 5
spawn mysql -u root -p
expect \"Enter password: \"
send \"${MYSQL_PWD}\r\"
			expect \"mysql>\"
			send \"ALTER USER 'root'@'localhost' IDENTIFIED BY 'MySQL!57';\r\"
expect \"mysql>\"
send \"uninstall plugin validate_password;\r\"
expect \"mysql>\"
send \"ALTER USER 'root'@'localhost' IDENTIFIED BY '';\r\"
expect \"mysql>\"
send \"CREATE USER 'vagrant'@'localhost';\r\"
expect \"mysql>\"
send \"CREATE DATABASE moodle;\r\"
expect \"mysql>\"
send \"GRANT ALL ON moodle.* TO 'moodle'@'localhost' IDENTIFIED BY 'secretpassword';\r\"
expect \"mysql>\"
send \"FLUSH PRIVILEGES;\r\"
expect \"mysql>\"
send \"quit;\r\"
expect eof
")

echo "$MYSQL_UPDATE"

#Moodle
wget https://download.moodle.org/stable36/moodle-latest-36.tgz
sudo mkdir /var/www/moodledata
sudo chmod -R 755 /var/www/moodledata
sudo chown -R apache:apache /var/www/moodledata
sudo tar xvzf moodle-latest-36.tgz -C /var/www/html/
sudo chown -R apache:apache /var/www/html/moodle
sudo chmod -R 755 /var/www/html/moodle

#sudo echo "<?php  // Moodle configuration file

#unset($CFG);
#global $CFG;
#$CFG = new stdClass();

#$CFG->dbtype    = 'mysqli';
#$CFG->dblibrary = 'native';
#$CFG->dbhost    = 'localhost';
#$CFG->dbname    = 'moodle';
#$CFG->dbuser    = 'moodle';
#$CFG->dbpass    = 'secretpassword';
#$CFG->prefix    = 'mdl_';
#$CFG->dboptions = array (
#  'dbpersist' => 0,
#  'dbport' => '',
#  'dbsocket' => '',
#  'dbcollation' => 'utf8mb4_general_ci',
#);

#$CFG->wwwroot   = 'http://192.168.33.10/moodle';
#$CFG->dataroot  = '/var/www/moodledate';
#$CFG->admin     = 'admin';

#$CFG->directorypermissions = 0777;

#require_once(__DIR__ . '/lib/setup.php');
#" > /var/www/html/moodle/config.php
sudo setenforce 0
sudo systemctl restart httpd.service