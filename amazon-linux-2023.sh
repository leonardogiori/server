
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
        location / {
            try_files $uri /$uri $uri/ =404;
        }
    }
}
'
echo "$nginx_conf" > /etc/nginx/nginx.conf
