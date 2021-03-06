#!/bin/bash
# Settings for MySQL 5.7
# Root password for MySQL
DB_ROOT=`</dev/urandom tr -dc '1234567890!@#$%qwertQWERTasdfgASDFGzxcvbZXCVB'| (head -c $1 > /dev/null 2>&1 || head -c 15)`
DB_NAME=`</dev/urandom tr -dc a-z0-9| (head -c $1 > /dev/null 2>&1 || head -c 8)`
DB_USER=`</dev/urandom tr -dc a-z0-9| (head -c $1 > /dev/null 2>&1 || head -c 8)`
DB_PASSWORD=`</dev/urandom tr -dc A-Za-z0-9| (head -c $1 > /dev/null 2>&1 || head -c 10)`
echo ""
CONFIG_DIR=$PWD
#Setup settings.txt for MySQL
    sed -i "s/DB_ROOT/$DB_ROOT/g" $CONFIG_DIR/settings.txt
    sed -i "s/DB_NAME/$DB_NAME/g" $CONFIG_DIR/settings.txt
    sed -i "s/DB_USER/$DB_USER/g" $CONFIG_DIR/settings.txt
    sed -i "s/DB_PASSWORD/$DB_PASSWORD/g" $CONFIG_DIR/settings.txt
    sed -i "s/DB_HOSTNAME/$DB_HOSTNAME/g" $CONFIG_DIR/settings.txt
    sed -i "s/DB_PORT/$DB_PORT/g" $CONFIG_DIR/settings.txt
#laravel .env setting 
    sed -i "s/DB_DATABASE/$DB_NAME/g" /var/www/myapp/.env
    sed -i "s/DB_USERNAME/$DB_USER/g" /var/www/myapp/.env
    sed -i "s/DB_PASSWORD/$DB_PASSWORD/g" /var/www/myapp/.env

#Install mysql-server-5.7 with empty root password 
sudo apt-key adv --keyserver pgp.mit.edu --recv-keys 5072E1F5
cat <<- EOF > /etc/apt/sources.list.d/mysql.list
deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7
EOF
sudo apt-get update
sudo apt-get install -y mysql-server-5.7
sleep 15
echo "Securing MySQL... "
sleep 5
    sudo apt install -y expect
    sleep 15
echo "--> Set root password for Mysql sever "
expect -f - <<-EOF
  set timeout 10
  spawn mysql_secure_installation
  expect "Would you like to setup VALIDATE PASSWORD plugin?"
  send -- "N\r"
  expect "New password:"
  send -- "$DB_ROOT\r"
  expect "Re-enter new password:"
  send -- "$DB_ROOT\r"
  expect "Remove anonymous users?"
  send -- "y\r"
  expect "Disallow root login remotely?"
  send -- "y\r"
  expect "Remove test database and access to it?"
  send -- "y\r"
  expect "Reload privilege tables now?"
  send -- "y\r"
  expect eof
EOF

sudo apt purge -y  expect

echo "Create database for Laravel app "

function create-laravel-db () {
  /usr/bin/mysqladmin -u root -p $DB_ROOT create database $DB_NAME charset utf8mb4;
  /usr/bin/mysqladmin -u root -p $DB_ROOT create user $DB_USER@$localhost identified by $DB_PASSWORD;
  /usr/bin/mysqladmin -u root -p $DB_ROOT grant all privileges on $DB_NAME.* to $DB_USER@$DB_HOSTNAME;
  /usr/bin/mysqladmin -u root -p $DB_ROOT flush privileges;
}

echo "Installing auth for Laravel "
cd /var/www/myapp
php artisan make:auth
php artisan migrate

echo "------------Done--------------"
