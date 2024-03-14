
# Amazon Linux 2023 - Server Install

# Exec .sh
#cd /tmp
#curl -L https://raw.githubusercontent.com/leonardogiori/server/main/amazon-linux-2023.sh?raw=true > script.sh
#chmod +x script.sh
#sudo script.sh
#rm script.sh
#cd /

# UPDATE
#sudo yum update

# NGINX
#sudo yum install nginx -y
#sudo systemctl enable nginx
#sudo systemctl start nginx

# PHP
#sudo yum install php8.2-fpm -y
#sudo systemctl enable php-fpm
#sudo systemctl start php-fpm

#php-fpm -v

#sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

nginx="
server {
  listen 80;
  server_name localhost;
  root /var/www/html;
}
"
echo "$nginx" > /etc/nginx/nginx.conf
