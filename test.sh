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
DOMAIN='giori.com.br'
PHP_VERSION='8.1'
NGINX_DEF='/etc/nginx/sites-available/default'
NGINX_GONF='/etc/nginx/nginx.conf'
LOG_FORMAT='$remote_addr - $remote_user [$time_local] "$request" $status $body_bytes_sent "$http_referer" "$http_user_agent" "$http_x_forwarded_for"'
MONIT_CONF='/etc/monit/monitrc'




# Clear Terminal
sudo clear



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

sudo mv "${NGINX_CONF}" "${NGINX_CONF}.old"
sudo mv "${NGINX_DEF}" "${NGINX_DEF}.old"

echo '    server {' >> $NGINX_DEF
echo '        listen                  [::]:443 ssl ipv6only=on;' >> $NGINX_DEF
echo '        listen                  443 ssl;' >> $NGINX_DEF
echo "        ssl_certificate         /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;" >> $NGINX_DEF
echo "        ssl_certificate_key     /etc/letsencrypt/live/${DOMAIN}/privkey.pem;" >> $NGINX_DEF
echo '        include                 /etc/letsencrypt/options-ssl-nginx.conf;' >> $NGINX_DEF
echo '        ssl_dhparam             /etc/letsencrypt/ssl-dhparams.pem;' >> $NGINX_DEF
echo '    server {' >> $NGINX_DEF
echo '        return 301 https://$host$request_uri;' >> $NGINX_DEF
echo '    }' >> $NGINX_DEF





sudo chmod 755 -R $NGINX_DEF

# Restart NGINX
echo -e "${B}Restart NGINX ${N}"
sudo systemctl reload nginx




fi
