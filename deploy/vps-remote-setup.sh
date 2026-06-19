#!/usr/bin/env bash
# Car IQ — full VPS setup (Ubuntu 24.04, IP-only, no SSL)
set -euo pipefail

APP_DIR="/var/www/car-iq"
APP_IP="${APP_IP:-207.180.208.172}"
GIT_REPO="https://github.com/nawar84/syaratiiq.git"
GIT_BRANCH="main"
DB_NAME="car_iq"
DB_USER="car_iq"
DB_PASS="${DB_PASS:?DB_PASS required}"
DEPLOY_USER="www-data"
PHP_VERSION="8.3"

log() { echo "[setup] $*"; }

log "Installing system packages..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y software-properties-common ca-certificates curl git unzip ufw gettext-base

if ! dpkg -l | grep -q php8.3-fpm; then
  add-apt-repository -y ppa:ondrej/php
  apt-get update -y
fi

apt-get install -y \
  nginx \
  "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-mysql" \
  "php${PHP_VERSION}-zip" "php${PHP_VERSION}-gd" "php${PHP_VERSION}-mbstring" \
  "php${PHP_VERSION}-curl" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-bcmath" \
  "php${PHP_VERSION}-intl" "php${PHP_VERSION}-redis" "php${PHP_VERSION}-opcache" \
  "php${PHP_VERSION}-readline" \
  mysql-server redis-server supervisor certbot python3-certbot-nginx

if ! command -v composer >/dev/null 2>&1; then
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

if ! command -v node >/dev/null 2>&1; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt-get install -y nodejs
fi

log "Configuring UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

log "PHP production overrides..."
cat > "/etc/php/${PHP_VERSION}/fpm/conf.d/99-cariq-production.ini" <<'PHPINI'
[PHP]
expose_php = Off
memory_limit = 512M
max_execution_time = 300
max_input_time = 300
upload_max_filesize = 100M
post_max_size = 120M
max_file_uploads = 30
date.timezone = Asia/Baghdad
[opcache]
opcache.enable = 1
opcache.enable_cli = 0
opcache.memory_consumption = 256
opcache.interned_strings_buffer = 16
opcache.max_accelerated_files = 20000
opcache.validate_timestamps = 0
opcache.revalidate_freq = 0
PHPINI
cp "/etc/php/${PHP_VERSION}/fpm/conf.d/99-cariq-production.ini" \
   "/etc/php/${PHP_VERSION}/cli/conf.d/99-cariq-production.ini"
systemctl restart "php${PHP_VERSION}-fpm"

log "MySQL database..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

log "Cloning project..."
mkdir -p "${APP_DIR}"
if [[ ! -d "${APP_DIR}/.git" ]]; then
  git clone --branch "${GIT_BRANCH}" "${GIT_REPO}" "${APP_DIR}"
else
  git -C "${APP_DIR}" fetch origin
  git -C "${APP_DIR}" checkout "${GIT_BRANCH}"
  git -C "${APP_DIR}" pull origin "${GIT_BRANCH}"
fi

BACKEND="${APP_DIR}/backend"

log "Creating .env..."
if [[ ! -f "${BACKEND}/.env" ]]; then
  cp "${APP_DIR}/deploy/.env.production" "${BACKEND}/.env"
  sed -i "s|__APP_DOMAIN__|${APP_IP}|g" "${BACKEND}/.env"
  sed -i "s|https://|http://|g" "${BACKEND}/.env"
  sed -i "s|__DB_PASSWORD__|${DB_PASS}|g" "${BACKEND}/.env"
  sed -i "s|__MAIL_HOST__|localhost|g" "${BACKEND}/.env"
  sed -i "s|__MAIL_USERNAME__||g" "${BACKEND}/.env"
  sed -i "s|__MAIL_PASSWORD__||g" "${BACKEND}/.env"
  sed -i "s|__SMS_API_KEY__||g" "${BACKEND}/.env"
  sed -i "s|__SMS_HTTP_URL__||g" "${BACKEND}/.env"
  sed -i "s|SMS_DRIVER=http|SMS_DRIVER=log|g" "${BACKEND}/.env"
  sed -i "s|SESSION_SECURE_COOKIE=true|SESSION_SECURE_COOKIE=false|g" "${BACKEND}/.env"
fi

log "Composer + Laravel..."
cd "${BACKEND}"
composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction
php artisan key:generate --force
php artisan migrate --force
php artisan db:seed --force
php artisan storage:link --force
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan event:cache
php artisan optimize

log "Permissions..."
chown -R www-data:www-data "${APP_DIR}"
chmod -R 775 "${BACKEND}/storage" "${BACKEND}/bootstrap/cache"

log "Nginx..."
cat > /etc/nginx/sites-available/car-iq <<NGINX
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name ${APP_IP} _;

    root ${BACKEND}/public;
    index index.php;
    charset utf-8;
    client_max_body_size 120M;

    access_log /var/log/nginx/car-iq-access.log;
    error_log  /var/log/nginx/car-iq-error.log warn;

    gzip on;
    gzip_vary on;
    gzip_types application/json application/javascript text/css text/plain image/svg+xml;

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
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        include fastcgi_params;
        fastcgi_read_timeout 300;
    }

    location ~ /\.(?!well-known).* { deny all; }
}
NGINX

ln -sf /etc/nginx/sites-available/car-iq /etc/nginx/sites-enabled/car-iq
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx redis-server mysql supervisor "php${PHP_VERSION}-fpm"
systemctl restart nginx redis-server mysql supervisor "php${PHP_VERSION}-fpm"

log "Supervisor..."
mkdir -p /var/log/car-iq
cat > /etc/supervisor/conf.d/car-iq-worker.conf <<SUP
[program:car-iq-worker]
process_name=%(program_name)s_%(process_num)02d
command=php ${BACKEND}/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/car-iq/worker.log
SUP
supervisorctl reread
supervisorctl update
supervisorctl restart car-iq-worker:* || supervisorctl start car-iq-worker:*

log "Cron scheduler..."
cat > /etc/cron.d/car-iq <<CRON
* * * * * www-data cd ${BACKEND} && php artisan schedule:run >> /var/log/car-iq/scheduler.log 2>&1
CRON
chmod 644 /etc/cron.d/car-iq

log "Smoke tests..."
curl -sf "http://127.0.0.1/up" >/dev/null && echo "OK /up"
curl -sf "http://127.0.0.1/api/statistics" >/dev/null && echo "OK /api/statistics"
curl -sf "http://127.0.0.1/api/cars" >/dev/null && echo "OK /api/cars"
LOGIN=$(curl -sf -X POST "http://127.0.0.1/api/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"1234"}')
echo "$LOGIN" | grep -q token && echo "OK Sanctum login"

log "DONE — API: http://${APP_IP}/api"
echo "DB_USER=${DB_USER}"
echo "DB_NAME=${DB_NAME}"
