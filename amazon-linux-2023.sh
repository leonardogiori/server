
# Amazon Linux 2023 - Server Install

# Exec .sh
# cd /tmp && curl -L https://raw.githubusercontent.com/leonardogiori/server/main/amazon-linux-2023.sh?raw=true > script.sh && chmod +x script.sh && sudo bash script.sh && rm script.sh && cd /

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

# CERTS OPEN SSL
sudo openssl genrsa -out /etc/ssl/certs/localhost.key 2048
sudo openssl req -new -key /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.csr -subj "/C=BR/ST=MG/L=Belo Horizonte/O=Giori/CN=giori"
sudo openssl x509 -req -in /etc/ssl/certs/localhost.csr -signkey /etc/ssl/certs/localhost.key -out /etc/ssl/certs/localhost.crt -days 365
sudo chown www:www /etc/ssl/certs/localhost.key
sudo chmod 644 /etc/ssl/certs/localhost.key
sudo openssl x509 -in /etc/ssl/certs/localhost.crt -text

#sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.backup

nginx_conf='
user nginx;
worker_processes 1;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;
events {
    worker_connections 1024;
}
http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }
    server {
        listen                  443 ssl;
        listen                  [::]:443 ssl;
        server_name ~^(site)\.(?<domain>.+)$;
        root /var/www/site/;
        location ~ "\.(gif|jpg|png|css|js|svg|jpeg|webp|avif)$" {
            try_files /$uri $uri =404;
        }
        location / {
            fastcgi_pass   php:9000;
            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        fastcgi_params;
            fastcgi_index  index.php;
            try_files /$uri $uri /$uri/index.php $uri/index.php =404;
        }
    }
    server {
        listen                  443 ssl default_server;
        listen                  [::]:443 ssl default_server;
        ssl_certificate         /etc/nginx/ssl/localhost.crt;
        ssl_certificate_key     /etc/nginx/ssl/localhost.key;
        ssl_protocols           SSLv3 TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers             HIGH:!aNULL:!MD5;
        client_max_body_size 32M;
        server_name ~^(?<subdomain>\w+)\.(?<domain>.+)$;
        root /var/www/;
        autoindex off;
        index index.php;
        allow all;
        location ~ ^/asset/(?:([^\/]+)/)?(.*)$ {
            try_files /data/storage/$1/$2 /data/static/$1/$2 /html/$domain/$subdomain/asset/$1/$2 /core/$1/asset/$2 /data/static/$domain/$subdomain/asset/$1/$2 /static/$1/$2;
        }
        location / {
            rewrite ^/([a-zA-Z0-9\.\-_\~@/]+)$ /index.php?_uri=$1 last;
            location = /index.php {
                fastcgi_pass   php:9000;
                fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include        fastcgi_params;
            }  
            allow all;   
        }
    }
}
'

echo "$nginx_conf" > /etc/nginx/nginx.conf
