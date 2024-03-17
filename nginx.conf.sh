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
        root /var/www/html;
        autoindex off;
        allow all;
        location ~ ^/(.*?)/acme-challenge/(.*?) {
            try_files $uri /$uri $uri/ =404;
        }
        location ~ \.txt$ {
            try_files $uri /$uri $uri/ =404;
        }
        location / {
            return 301 https://$host$request_uri;
        }
    }
    server {
        listen                  443 ssl default_server;
        listen                  [::]:443 ssl default_server;
        client_max_body_size 32M;
        server_name ~^(?<subdomain>\w+)\.(?<domain>.+)$;
        root /var/www/;
        autoindex off;
        index index.php;
        allow all;
        ssl_certificate         /etc/letsencrypt/live/giori.com.br/fullchain.pem;
        ssl_certificate_key     /etc/letsencrypt/live/giori.com.br/privkey.pem;
        ssl_protocols           SSLv3 TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers             HIGH:!aNULL:!MD5;
        location ~ ^/asset/(?:([^\/]+)/)?(.*)$ {
            try_files /data/storage/$1/$2 /data/static/$1/$2 /html/$domain/$subdomain/asset/$1/$2 /core/$1/asset/$2 /data/static/$domain/$subdomain/asset/$1/$2 /static/$1/$2;
        }
        location /adminer.php {
            fastcgi_pass unix:/var/run/php-fpm/www.sock;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
            allow all;
            try_files $uri /$uri $uri/ =404;
        }
        location / {
            rewrite ^/([a-zA-Z0-9\.\-_\~@/]+)$ /index.php?_uri=$1 last;
            location = /index.php {
                fastcgi_pass unix:/var/run/php-fpm/www.sock;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include fastcgi_params;
            }  
            allow all;
        }
    }
    server {
        listen 443 ssl default_server;
        listen [::]:443 ssl default_server;
        client_max_body_size 32M;
        server_name ~^(?<subdomain>\w+)\.(?<domain>.+)$;
        root /var/www/nexus/;
        autoindex off;
        index index.php;
        allow all;
        ssl_certificate /etc/letsencrypt/live/giori.com.br/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/giori.com.br/privkey.pem;
        ssl_protocols SSLv3 TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!MD5;
        location / {
            rewrite ^/([a-zA-Z0-9\.\-_\~@/]+)$ /index.php?_uri=$1 last;
            location = /index.php {
                fastcgi_pass unix:/var/run/php-fpm/www.sock;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include fastcgi_params;
            }  
            allow all;
        }
    }
}
'
echo "$nginx_conf" > /etc/nginx/nginx.conf
