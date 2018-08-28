#!/bin/sh

#-- This file is a clone from https://github.com/digitalocean/do_user_scripts/blob/master/Ubuntu-14.04/cms/wordpress-nginx.sh
# As you can expected this bash script is not working on Ubuntu 16.04 and also doesn't have PHP 7.0. Another problem is it doesn't
# have functions unlike AbhishekGlosh's solution. It's somewhat hard to extend and customize.
# --#

#
# WordPress Setup Script
#
# This script will install and configure WordPress on
# an Ubuntu 14.04 droplet
# Generate root and wordpress mysql passwords
rootmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;
wpmysqlpass=`dd if=/dev/urandom bs=1 count=32 2>/dev/null | base64 -w 0 | rev | cut -b 2- | rev | tr -dc 'a-zA-Z0-9'`;

# Write passwords to file
echo "MySQL Passwords for this droplet " > /etc/motd.tail;
echo "-----------------------------------" >> /etc/motd.tail;
echo "Root MySQL Password: $rootmysqlpass" >> /etc/motd.tail;
echo "Wordpress MySQL Database: mwdb" >> /etc/motd.tail;
echo "Wordpress MySQL Username: mwsql" >> /etc/motd.tail;
echo "Wordpress MySQL Password: $wpmysqlpass" >> /etc/motd.tail;
echo "-----------------------------------" >> /etc/motd.tail;
echo "You can remove this information with 'rm -f /etc/motd.tail'" >> /etc/motd.tail;
# When install mysql it doesn't ask any mysql root password,so set the environment variables
export DEBIAN_FRONTEND=noninteractive
# Update Ubuntu
apt-get -y update;
apt-get -y upgrade;
# Install deb-conf utils and give the mysql root password
apt-get -y install debconf-utils
echo mysql-server mysql-server/root_password password $rootmysqlpass | sudo debconf-set-selections
echo mysql-server mysql-server/root_password_again password $rootmysqlpass | sudo debconf-set-selections

#to get nginx stable versions and get the key from on it.
echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/nginx-stable.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys C300EE8C
sudo apt-get update
# Check if PHP, Mysql & Nginx are installed. If not present, install the missing packages
for package in  mysql-server php-fpm php-mysql mysql-client unzip nginx;
do
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $package|grep "install ok installed")
echo Checking for somelib: $PKG_OK
if [ "" == "$PKG_OK" ]; then
  echo "No somelib. Setting up somelib."
  sudo apt-get -y install $package
fi
done
#start nginx& mysql
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mysql
sudo systemctl enable mysql
# Download and uncompress WordPress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip;
cd /tmp/ || exit;
unzip /tmp/wordpress.zip;
# Set up database user and give privillages
# Created DB example_db(example.com_db has mysql synatx error), user wordpress
/usr/bin/mysql -u root -p$rootmysqlpass -h localhost -e "CREATE DATABASE example_db";
/usr/bin/mysql -uroot -p$rootmysqlpass -e "CREATE USER wordpress@localhost IDENTIFIED BY '"$wpmysqlpass"'";
/usr/bin/mysql -uroot -p$rootmysqlpass -e "GRANT ALL PRIVILEGES ON example_db.* TO wordpress@localhost";
/usr/bin/mysql -uroot -p$rootmysqlpass -e "FLUSH PRIVILEGES";



# Configure PHP
sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/"  /etc/php/7.2/fpm/php.ini
sed -i "s|listen = 127.0.0.1:9000|listen = /var/run/php5-fpm.sock|"  /etc/php/7.2/fpm/pool.d/www.conf;

#start php service
sudo systemctl restart php7.2-fpm
sudo systemctl enable php7.2-fpm
#Ask the user for a domain name(givename as example.com)
read -p "Enter your name : " name
sed -i "s/127.0.0.1 localhost/127.0.0.1 $name/g" /etc/hosts;

# Configure Nginx
mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
cat > /etc/nginx/sites-available/default << "EOF"
server {
        listen 80 default_server;
        listen [::]:80 default_server ipv6only=on;
        root /var/www/html;
        index index.php index.html index.htm;
        server_name localhost;
        location / {
                        # First attempt to serve request as file, then
                        # as directory, then fall back to displaying a 404.
                        try_files $uri $uri/ /index.php?q=$uri&$args;
                        # Uncomment to enable naxsi on this location
                        # include /etc/nginx/naxsi.rules
        }
        error_page 404 /404.html;
        error_page 500 502 503 504 /50x.html;
        location = /50x.html {
                        root /usr/share/nginx/html;
        }
        location ~ \.php$ {
                        try_files $uri =404;
                        fastcgi_split_path_info ^(.+\.php)(/.+)$;
                        fastcgi_pass unix:/run/php/php7.2-fpm.sock;
                        fastcgi_index index.php;
                        include fastcgi.conf;
        }
}
EOF
sed -i "s/server_name locahost;/server_name $name;/g" /etc/nginx/sites-available/default;

# Add PHP info
echo "<?php phpinfo();?>" > /var/www/html/info.php
# Configure Nginx sites-available
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/wordpress
sudo rm /etc/nginx/sites-available/default
sudo rm /etc/nginx/sites-enabled/default
sudo ln -s /etc/nginx/sites-available/wordpress /etc/nginx/sites-enabled/wordpress
#Configure WordPress
cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php;
sed -i "s|'DB_NAME', 'database_name_here'|'DB_NAME', 'example_db'|g" /tmp/wordpress/wp-config.php;
sed -i "s/'DB_USER', 'username_here'/'DB_USER', 'wordpress'/g" /tmp/wordpress/wp-config.php;
sed -i "s/'DB_PASSWORD', 'password_here'/'DB_PASSWORD', '$wpmysqlpass'/g" /tmp/wordpress/wp-config.php;
for i in `seq 1 8`
do
wp_salt=$(</dev/urandom tr -dc 'a-zA-Z0-9!@#$%^&*()\-_ []{}<>~`+=,.;:/?|' | head -c 64 | sed -e 's/[\/&]/\\&/g');
sed -i "0,/put your unique phrase here/s/put your unique phrase here/$wp_salt/" /tmp/wordpress/wp-config.php;
done
cp -Rf /tmp/wordpress/* /var/www/html/.;
rm -f /var/www/index.html;
chown -Rf www-data:www-data /var/www/html;
systemctl nginx restart;


