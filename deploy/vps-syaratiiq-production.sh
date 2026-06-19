#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/var/www/syaratiiq"
BACKEND="${APP_DIR}/backend"
GIT_REPO="https://github.com/nawar84/syaratiiq.git"
GIT_BRANCH="main"
DOMAIN="syaratiiq.com"
WWW_DOMAIN="www.syaratiiq.com"
DB_NAME="syaratiiq"
DB_USER="syarati"
DB_PASS='Syarati@2026!'
ADMIN_EMAIL="local55555@gmail.com"
PHP_VERSION="8.3"

log() { echo "[deploy] $*"; }
run() { log ">>> $*"; "$@"; }

fix_and_continue() {
  log "WARNING: $* — attempting recovery..."
}

log "=== 1. Verify stack ==="
run php -v
run composer --version
run mysql --version
run nginx -v
systemctl is-active --quiet mysql || run systemctl start mysql
systemctl is-active --quiet nginx || run systemctl start nginx
systemctl is-active --quiet "php${PHP_VERSION}-fpm" || run systemctl start "php${PHP_VERSION}-fpm"

log "=== Install missing packages ==="
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y \
  "php${PHP_VERSION}-fpm" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-mysql" \
  "php${PHP_VERSION}-zip" "php${PHP_VERSION}-gd" "php${PHP_VERSION}-mbstring" \
  "php${PHP_VERSION}-curl" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-bcmath" \
  "php${PHP_VERSION}-intl" "php${PHP_VERSION}-redis" "php${PHP_VERSION}-opcache" \
  redis-server certbot python3-certbot-nginx supervisor curl git unzip || fix_and_continue "apt packages"

if ! command -v composer >/dev/null 2>&1; then
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

log "=== PHP-FPM production tuning ==="
cat > "/etc/php/${PHP_VERSION}/fpm/conf.d/99-syaratiiq.ini" <<'INI'
[PHP]
expose_php = Off
memory_limit = 512M
max_execution_time = 300
upload_max_filesize = 100M
post_max_size = 120M
max_file_uploads = 30
date.timezone = Asia/Baghdad
[opcache]
opcache.enable = 1
opcache.memory_consumption = 256
opcache.max_accelerated_files = 20000
opcache.validate_timestamps = 0
INI
cp "/etc/php/${PHP_VERSION}/fpm/conf.d/99-syaratiiq.ini" \
   "/etc/php/${PHP_VERSION}/cli/conf.d/99-syaratiiq.ini"
systemctl restart "php${PHP_VERSION}-fpm"

log "=== 2. Clone repository ==="
mkdir -p "${APP_DIR}"
if [[ ! -d "${APP_DIR}/.git" ]]; then
  git clone --branch "${GIT_BRANCH}" "${GIT_REPO}" "${APP_DIR}"
else
  git -C "${APP_DIR}" fetch origin
  git -C "${APP_DIR}" checkout "${GIT_BRANCH}"
  git -C "${APP_DIR}" pull origin "${GIT_BRANCH}"
fi

log "=== 6. MySQL database ==="
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "ALTER USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

log "=== 4-7. Create .env ==="
if [[ ! -f "${BACKEND}/.env" ]]; then
  cp "${APP_DIR}/deploy/.env.production" "${BACKEND}/.env"
fi

sed -i "s|__APP_DOMAIN__|${DOMAIN}|g" "${BACKEND}/.env"
sed -i "s|__DB_PASSWORD__|${DB_PASS}|g" "${BACKEND}/.env"
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" "${BACKEND}/.env"
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" "${BACKEND}/.env"
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASS}|" "${BACKEND}/.env"
sed -i "s|__MAIL_HOST__|localhost|g" "${BACKEND}/.env"
sed -i "s|__MAIL_USERNAME__||g" "${BACKEND}/.env"
sed -i "s|__MAIL_PASSWORD__||g" "${BACKEND}/.env"
sed -i "s|__SMS_API_KEY__||g" "${BACKEND}/.env"
sed -i "s|__SMS_HTTP_URL__||g" "${BACKEND}/.env"
sed -i "s|SMS_DRIVER=http|SMS_DRIVER=log|g" "${BACKEND}/.env"

log "=== 3. Composer install ==="
cd "${BACKEND}"
run composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction

log "=== 5. APP_KEY ==="
if ! grep -q '^APP_KEY=base64:' "${BACKEND}/.env"; then
  run php artisan key:generate --force
fi

log "=== 8-10. Migrate, storage, optimize ==="
run php artisan migrate --force
run php artisan storage:link --force
run php artisan config:cache
run php artisan route:cache
run php artisan view:cache
run php artisan event:cache
run php artisan optimize

log "=== 11. Permissions ==="
chown -R www-data:www-data "${APP_DIR}"
chmod -R 775 "${BACKEND}/storage" "${BACKEND}/bootstrap/cache"
ln -sfn "${BACKEND}/public" "${APP_DIR}/public"

log "=== 13-17. Nginx virtual host ==="
cat > /etc/nginx/sites-available/syaratiiq <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} ${WWW_DOMAIN};

    root ${APP_DIR}/public;
    index index.php;
    charset utf-8;
    client_max_body_size 120M;

    access_log /var/log/nginx/syaratiiq-access.log;
    error_log  /var/log/nginx/syaratiiq-error.log warn;

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

ln -sf /etc/nginx/sites-available/syaratiiq /etc/nginx/sites-enabled/syaratiiq
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx "php${PHP_VERSION}-fpm" mysql redis-server
systemctl restart "php${PHP_VERSION}-fpm"
systemctl restart nginx

log "=== 18-20. SSL with Certbot ==="
certbot --nginx -d "${DOMAIN}" -d "${WWW_DOMAIN}" \
  --non-interactive --agree-tos -m "${ADMIN_EMAIL}" --redirect || {
  fix_and_continue "certbot failed — check DNS A records point to this server"
  certbot --nginx -d "${DOMAIN}" -d "${WWW_DOMAIN}" \
    --non-interactive --agree-tos -m "${ADMIN_EMAIL}" --redirect --force-renewal || true
}

log "=== Supervisor queue workers ==="
mkdir -p /var/log/syaratiiq
cat > /etc/supervisor/conf.d/syaratiiq-worker.conf <<SUP
[program:syaratiiq-worker]
process_name=%(program_name)s_%(process_num)02d
command=php ${BACKEND}/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/syaratiiq/worker.log
SUP
supervisorctl reread || true
supervisorctl update || true
supervisorctl restart syaratiiq-worker:* || supervisorctl start syaratiiq-worker:* || true

log "=== Scheduler cron ==="
cat > /etc/cron.d/syaratiiq <<CRON
* * * * * www-data cd ${BACKEND} && php artisan schedule:run >> /var/log/syaratiiq/scheduler.log 2>&1
CRON
chmod 644 /etc/cron.d/syaratiiq

log "=== 21. Verification ==="
HTTP_CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://${DOMAIN}/")
API_CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://${DOMAIN}/api/statistics")
UP_CODE=$(curl -sk -o /dev/null -w '%{http_code}' "https://${DOMAIN}/up")

echo "HTTPS homepage: ${HTTP_CODE}"
echo "HTTPS /api/statistics: ${API_CODE}"
echo "HTTPS /up: ${UP_CODE}"

LARAVEL_VER=$(cd "${BACKEND}" && php artisan --version 2>/dev/null || echo "unknown")
PHP_VER=$(php -r 'echo PHP_VERSION;')
SSL_EXP=$(certbot certificates 2>/dev/null | grep -A2 "${DOMAIN}" | grep "Expiry Date" || echo "check certbot certificates")

echo ""
echo "========== DEPLOYMENT REPORT =========="
echo "PHP version:        ${PHP_VER}"
echo "Laravel version:    ${LARAVEL_VER}"
echo "Database:           ${DB_NAME} @ localhost (user: ${DB_USER})"
echo "MySQL status:       $(systemctl is-active mysql)"
echo "Nginx status:       $(systemctl is-active nginx)"
echo "PHP-FPM status:     $(systemctl is-active php${PHP_VERSION}-fpm)"
echo "Redis status:       $(systemctl is-active redis-server)"
echo "SSL:                ${SSL_EXP}"
echo "Public URL:         https://${DOMAIN}"
echo "API URL:            https://${DOMAIN}/api"
echo "Project path:       ${APP_DIR}"
echo "Homepage HTTP code: ${HTTP_CODE}"
echo "API HTTP code:      ${API_CODE}"
if [[ "${HTTP_CODE}" != "200" ]]; then
  echo "WARNING: Homepage did not return 200 — check nginx error log"
  tail -20 /var/log/nginx/syaratiiq-error.log 2>/dev/null || true
fi
echo "======================================="
