
# Amazon Linux 2023 - Server Install

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
    types_hash_max_size 4096;
    default_type application/octet-stream;
    #access_log /var/log/nginx/access.log main;
    sendfile on;
    keepalive_timeout 65;
    server {
        listen 80;
        server_name _;
        return 301 https://$host$request_uri;
    }
    server {
        listen                  443 ssl default_server;
        listen                  [::]:443 ssl default_server;
        ssl_certificate         /etc/ssl/certs/localhost.crt;
        ssl_certificate_key     /etc/ssl/certs/localhost.key;
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
                fastcgi_pass unix:/var/run/php-fpm/www.sock;
                #fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                includefastcgi_params;
            }  
            allow all;   
        }
    }
}
'
echo "$nginx_conf" > /etc/nginx/nginx.conf
