
DOMAIN='giori.com.br'
PHP_VERSION='8.1'
NGINX_DEF='/etc/nginx/sites-available/default'
LOG_FORMAT='$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"'
MONIT_CONF='/etc/monit/monitrc'


# Configure NGINX
echo -e "${B}Configure NGINX ${N}"

sudo chmod 777 -R $NGINX_DEF
echo 'user www-data;' > $NGINX_DEF
echo 'worker_processes auto;' >> $NGINX_DEF #1;' >> $NGINX_DEF
echo 'error_log /var/log/nginx/error.log warn;' >> $NGINX_DEF
echo 'pid       /var/run/nginx.pid;' >> $NGINX_DEF
echo 'events {' >> $NGINX_DEF
echo '    worker_connections 1024;' >> $NGINX_DEF
echo '}' >> $NGINX_DEF
echo 'http {' >> $NGINX_DEF
echo '    include /etc/nginx/mime.types;' >> $NGINX_DEF
echo '    default_type application/octet-stream;' >> $NGINX_DEF
echo "    log_format main '${LOG_FORMAT}';" >> $NGINX_DEF
echo '    access_log /var/log/nginx/access.log main;' >> $NGINX_DEF
echo '    sendfile on;' >> $NGINX_DEF
echo '    keepalive_timeout 65;' >> $NGINX_DEF


echo '    server {' >> $NGINX_DEF


echo '        listen                  [::]:443 ssl ipv6only=on;' >> $NGINX_DEF
echo '        listen                  443 ssl;' >> $NGINX_DEF
echo "        ssl_certificate         /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;" >> $NGINX_DEF
echo "        ssl_certificate_key     /etc/letsencrypt/live/${DOMAIN}/privkey.pem;" >> $NGINX_DEF
echo '        include                 /etc/letsencrypt/options-ssl-nginx.conf;' >> $NGINX_DEF
echo '        ssl_dhparam             /etc/letsencrypt/ssl-dhparams.pem;' >> $NGINX_DEF


echo '        root /var/www/html/;' >> $NGINX_DEF
echo '        index index.php;' >> $NGINX_DEF

echo '        server_name ~^(?<subdomain>\w+)\.(?<domain>.+)$;' >> $NGINX_DEF

echo '        client_max_body_size 32M;' >> $NGINX_DEF
echo '        autoindex off;' >> $NGINX_DEF
echo '        allow all;' >> $NGINX_DEF

echo '        location ~ ^/(img|css|js|video)/ {' >> $NGINX_DEF        
echo '            try_files /$subdomain/$domain$uri /$subdomain/default$uri /$uri;' >> $NGINX_DEF
echo '        }' >> $NGINX_DEF

echo '        location / {' >> $NGINX_DEF
echo '            rewrite ^/([a-zA-Z0-9\.\-_\~/]+)$ /index.php?_uri=$1 last;' >> $NGINX_DEF
echo '            location = /index.php {' >> $NGINX_DEF
echo '                  include snippets/fastcgi-php.conf;' >> $NGINX_DEF
echo "                  fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;" >> $NGINX_DEF
echo '            }' >> $NGINX_DEF
echo '            allow all; ' >> $NGINX_DEF
echo '        }' >> $NGINX_DEF

echo '    }' >> $NGINX_DEF



echo '    server {' >> $NGINX_DEF
echo '      return 301 https://$host$request_uri;' >> $NGINX_DEF
echo '    }' >> $NGINX_DEF



echo '}' >> $NGINX_DEF
sudo chmod 755 -R $NGINX_DEF

# Restart NGINX
echo -e "${B}Restart NGINX ${N}"
sudo systemctl reload nginx
