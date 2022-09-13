#!/bin/bash

###############################################################################################################################
# Intall server - Ubuntu 20.04                                                                                                #
# Version - 0.1                                                                                                               #
###############################################################################################################################

# Colors
RED=$'\e[0;31m'
GREEN=$'\e[0;32m'
BLUE=$'\e[0;34m'
B=$'\n\e[1;33m'
C=$'\e[1;30m'
N=$'\e[0m'

# Vars
PHP_VERSION='8.1'
NGINX_DEF='/etc/nginx/sites-enabled/default'
MONIT_CONF='/etc/monit/monitrc'

# Clear Terminal
sudo clear

# If install server
read -p "Are you actually installing the server? (y|n)" CHOICE
if [ "$CHOICE" = "y" ]; then


# UBUNT #######################################################################################################################
###############################################################################################################################

# Install Ubuntu
echo -e "${B}Update and Upgrade Ubuntu 20.04 ${N}"
sudo apt-get update -y -q && sudo apt-get upgrade -y -q

# Ubuntu Commons
echo -e "${B}\n# Install Commons ${N}"
sudo apt install ca-certificates \
                 apt-transport-https \
                 software-properties-common \
                 openssl libzip-dev \
                 zip \
                 unzip \
                 fail2ban \
                 htop \
                 sqlite3 \
                 nload \
                 mlocate \
                 nano \
                 memcached -y -q

# Add PHP repository
echo -e "${B}Add repository PPA:PHP ${N}"
sudo add-apt-repository ppa:ondrej/php -y

# Add NGINX repository
echo -e "${B}Add repository PPA:NGINX ${N}"
sudo add-apt-repository ppa:ondrej/nginx -y

# Update Ubuntu
echo -e "${B}Update Ubuntu ${N}"
sudo apt update -y

# MARIADB #####################################################################################################################
###############################################################################################################################

# Install MariaDB
echo -e "${B}Install MariaDB ${N}"
sudo apt install mariadb-server -y

# MariaDB Secure
echo -e "${B}Install MariaDB  Secure ${N}"
sudo mysql_secure_installation <<EOF

n
n
n
n
n
EOF

# NGINX #######################################################################################################################
###############################################################################################################################

# Install NGINX
echo -e "${B}Install Nginx ${N}"
sudo apt install nginx -y

# Install NGINX Secure
echo -e "${B}Install NGINX Secure ${N}"
sudo ufw allow "Nginx HTTP"
#sudo ufw status

# Configure NGINX
echo -e "${B}Configure NGINX ${N}"
sudo chmod 777 -R $NGINX_DEF
echo "server {" > $NGINX_DEF
echo "    listen 80 default_server;" >> $NGINX_DEF
echo "    listen [::]:80 default_server;" >> $NGINX_DEF
echo "    root /var/www/html;" >> $NGINX_DEF
echo "    index index.php index.html index.nginx-debian.html;" >> $NGINX_DEF
echo "    server_name _;" >> $NGINX_DEF
echo "    location / {" >> $NGINX_DEF
echo "        try_files \$uri \$uri/ =404;" >> $NGINX_DEF
echo "    }" >> $NGINX_DEF
echo "    location ~ \.php$ {" >> $NGINX_DEF
echo "        include snippets/fastcgi-php.conf;" >> $NGINX_DEF
echo "        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;" >> $NGINX_DEF
echo "    }" >> $NGINX_DEF
echo "}" >> $NGINX_DEF
sudo chmod 755 -R $NGINX_DEF

# Restart NGINX
echo -e "${B}Restart NGINX ${N}"
sudo systemctl reload nginx

# PHP #########################################################################################################################
###############################################################################################################################

# Install PHP
echo -e "${B}Install PHP ${PHP_VERSION} ${N}"
sudo apt install php${PHP_VERSION}-fpm -y

# Install PHP Extensions
echo -e "${B}Install PHP ${PHP_VERSION} Extensions ${N}"
sudo apt install php-common \
                 php-mysql \
                 php-cgi \
                 php-mbstring \
                 php-curl \
                 php-gd \
                 php-xml \
                 php-xmlrpc \
                 php-zip -y -q
sudo phpenmod pdo

# Restart PHP
echo -e "${B}Restart PHP ${N}"
sudo systemctl reload "php${PHP_VERSION}-fpm"

# Configure PHP
echo -e "${B}Configure PHP ${PHP_VERSION} Extensions ${N}"
# Disable external access to PHP-FPM scripts
# https://serverfault.com/questions/627903/is-the-php-option-cgi-fix-pathinfo-really-dangerous-with-nginx-php-fpm
sudo sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" "/etc/php/${PHP_VERSION}/fpm/php.ini"
sudo sed -i "s/display_errors = Off/display_errors = On/" "/etc/php/${PHP_VERSION}/fpm/php.ini"

# MONIT #######################################################################################################################
###############################################################################################################################

# Install Munit
echo -e "${B}Install Monit ${N}"
sudo apt install monit -y -q

# Configure Monit
echo -e "${B}Configure Monit ${N}"
sudo chmod 777 -R $MONIT_CONF
sudo sed -i "s/set daemon 120/set daemon 10/g" $MONIT_CONF

# Monit - nginx
echo "#nginx" >> $MONIT_CONF
echo "check process nginx with pidfile /opt/nginx/logs/nginx.pid" >> $MONIT_CONF
echo "   start program = \"/etc/init.d/nginx start\"" >> $MONIT_CONF
echo "   stop  program = \"/etc/init.d/nginx stop\"" >> $MONIT_CONF
echo "   if failed host 127.0.0.1 port 80 then restart" >> $MONIT_CONF
echo "   if cpu is greater than 40% for 2 cycles then alert" >> $MONIT_CONF
echo "   if cpu > 60% for 5 cycles then restart " >> $MONIT_CONF
echo "   if 10 restarts within 10 cycles then timeout" >> $MONIT_CONF

# Monit MariaDB
echo "#mariadb" >> $MONIT_CONF
echo "check process mysqld with pidfile /var/run/mysqld/mysqld.pid" >> $MONIT_CONF
echo "   group database" >> $MONIT_CONF
echo "   start program = \"/etc/init.d/mysql start\"" >> $MONIT_CONF
echo "   stop program = \"/etc/init.d/mysql stop\"" >> $MONIT_CONF
echo "   if failed host 127.0.0.1 port 3306 then restart" >> $MONIT_CONF
echo "   if 5 restarts within 5 cycles then timeout" >> $MONIT_CONF

# Monit PHP
echo "#php" >> $MONIT_CONF
echo "check process php${PHP_VERSION}-fpm with pidfile /var/run/php/php${PHP_VERSION}-fpm.pid" >> $MONIT_CONF
echo "   start program = \"/etc/init.d/php${PHP_VERSION}-fpm start\"" >> $MONIT_CONF
echo "   stop program = \"/etc/init.d/php${PHP_VERSION}-fpm stop\"" >> $MONIT_CONF
echo "    if cpu usage > 80% for 5 cycles then alert" >> $MONIT_CONF
echo "    if failed unixsocket /var/run/php/php${PHP_VERSION}-fpm.sock then restart" >> $MONIT_CONF
echo "    if 5 restarts within 5 cycles then timeout" >> $MONIT_CONF

#echo "#File size" >> $MONIT_CONF
#echo "check file syslog with path /var/log/syslog" >> $MONIT_CONF
#echo "    if size > 50 MB then alert" >> $MONIT_CONF

#echo "#Filesystem" >> $MONIT_CONF
#echo "check filesystem "sda1" with path /dev/sda1" >> $MONIT_CONF
#echo "    if space usage > 95% for 10 cycles then alert" >> $MONIT_CONF

# Enable httpd
echo "#httpd" >> $MONIT_CONF
echo "set httpd port 2812 and" >> $MONIT_CONF
echo "  use address localhost  # only accept connection from localhost" >> $MONIT_CONF
echo "  allow localhost        # allow localhost to connect to the server and" >> $MONIT_CONF
echo "  allow admin:monit      # require user 'admin' with password 'monit'" >> $MONIT_CONF

sudo chmod 700 -R $MONIT_CONF

# Restart Monit
echo -e "${B}Restart Monit ${N}"
sudo monit reload
  
# CONFIGURATIONS  #############################################################################################################
###############################################################################################################################

# Basic app settings 
echo -e "${B}Configure ${N}"

echo -e "Set perms for www..."
sudo chown -R www-data:www-data /var/www/html
sudo chmod 777 -R /var/www/html

echo -e "Create Info.."
echo -e "<?php phpinfo(); ?>" > /var/www/html/info.php

echo -e "Create Index.."
echo -e "<?php die('Tanks for using Hash!'); ?>" > /var/www/html/index.php

echo -e "Create Mysql..."
echo -e "<?php \$conn = new mysqli('localhost', 'root', ''); if (\$conn->connect_error) { die('Connection failed: ' . \$conn->connect_error); } echo 'Connected successfully'; ?>" > /var/www/html/mysql.php

# RESTART #####################################################################################################################
###############################################################################################################################

# Restart NGINX
echo -e "${B}Restart NGINX ${N}"
sudo systemctl reload nginx

# Restart PHP
echo -e "${B}Restart PHP ${PHP_VERSION} ${N}"
sudo systemctl reload "php${PHP_VERSION}-fpm"

# Finished - TODO - Check integrity
echo -e "\n${GREEN}Thank for using! ${N}\n"

fi

