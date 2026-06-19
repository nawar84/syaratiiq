#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/var/www/syaratiiq"
BACKEND="${APP_DIR}/backend"
PUBLIC="${APP_DIR}/public"
GIT_REPO="https://github.com/nawar84/syaratiiq.git"
DOMAIN="syaratiiq.com"
WWW="www.syaratiiq.com"
DB_NAME="syaratiiq"
DB_USER="syarati"
DB_PASS='Syarati@2026!'
PHP_VER="8.3"

export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y git nginx mysql-server redis-server certbot python3-certbot-nginx \
  php${PHP_VER}-fpm php${PHP_VER}-cli php${PHP_VER}-mysql php${PHP_VER}-zip php${PHP_VER}-gd \
  php${PHP_VER}-mbstring php${PHP_VER}-curl php${PHP_VER}-xml php${PHP_VER}-bcmath \
  php${PHP_VER}-intl php${PHP_VER}-redis php${PHP_VER}-opcache unzip curl || true

command -v composer >/dev/null || {
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
}

mkdir -p "${APP_DIR}"
if [[ ! -d "${APP_DIR}/.git" ]]; then
  git clone "${GIT_REPO}" "${APP_DIR}"
else
  git -C "${APP_DIR}" fetch origin
  git -C "${APP_DIR}" reset --hard origin/main
fi

mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

if [[ ! -f "${BACKEND}/.env" ]]; then
  cp "${APP_DIR}/deploy/.env.production" "${BACKEND}/.env"
fi

sed -i "s|__APP_DOMAIN__|${DOMAIN}|g" "${BACKEND}/.env"
sed -i "s|__DB_PASSWORD__|${DB_PASS}|g" "${BACKEND}/.env"
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" "${BACKEND}/.env"
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" "${BACKEND}/.env"
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" "${BACKEND}/.env"
sed -i "s|APP_URL=.*|APP_URL=https://${DOMAIN}|" "${BACKEND}/.env"
sed -i "s|APP_DEBUG=.*|APP_DEBUG=false|" "${BACKEND}/.env"
sed -i "s|APP_ENV=.*|APP_ENV=production|" "${BACKEND}/.env"
sed -i "s|SMS_DRIVER=http|SMS_DRIVER=log|g" "${BACKEND}/.env"
sed -i "s|__MAIL_HOST__|localhost|g; s|__MAIL_USERNAME__||g; s|__MAIL_PASSWORD__||g; s|__SMS_API_KEY__||g; s|__SMS_HTTP_URL__||g" "${BACKEND}/.env"

ln -sfn "${BACKEND}/public" "${PUBLIC}"

cd "${BACKEND}"
composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction
php artisan key:generate --force
php artisan migrate --force
php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

chown -R www-data:www-data "${APP_DIR}"
chmod -R 775 "${BACKEND}/storage" "${BACKEND}/bootstrap/cache"

cat > /etc/nginx/sites-available/syaratiiq <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} ${WWW};

    root ${PUBLIC};
    index index.php;
    charset utf-8;
    client_max_body_size 120M;

    location ^~ /storage/ {
        alias ${BACKEND}/storage/app/public/;
        expires 30d;
        access_log off;
        try_files \$uri =404;
    }

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${PHP_VER}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* { deny all; }
}
NGINX

ln -sf /etc/nginx/sites-available/syaratiiq /etc/nginx/sites-enabled/syaratiiq
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl restart php${PHP_VER}-fpm nginx

certbot --nginx -d "${DOMAIN}" -d "${WWW}" --non-interactive --agree-tos -m local55555@gmail.com --redirect || true
systemctl reload nginx

curl -sf "http://127.0.0.1/up" >/dev/null
echo DEPLOY_OK
