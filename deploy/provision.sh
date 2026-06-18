#!/usr/bin/env bash
# Car IQ — Ubuntu VPS initial provisioning (run as root once)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/deploy.conf"

if [[ ! -f "${CONF_FILE}" ]]; then
  echo "Missing ${CONF_FILE}. Copy deploy.conf.example to deploy.conf and edit it."
  exit 1
fi

# shellcheck source=deploy.conf
source "${CONF_FILE}"

PHP_VERSION="${PHP_VERSION:-8.3}"
export DEBIAN_FRONTEND=noninteractive

log() { echo "[provision] $*"; }

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "Run as root: sudo bash deploy/provision.sh"
    exit 1
  fi
}

require_root

log "Updating Ubuntu packages..."
apt-get update -y
apt-get upgrade -y
apt-get install -y software-properties-common ca-certificates lsb-release gnupg2 ufw curl git unzip gettext-base

log "Adding PHP ${PHP_VERSION} repository..."
add-apt-repository -y ppa:ondrej/php
apt-get update -y

log "Installing Nginx, PHP, MySQL, Redis, Supervisor, Node.js LTS..."
apt-get install -y \
  nginx \
  "php${PHP_VERSION}-fpm" \
  "php${PHP_VERSION}-cli" \
  "php${PHP_VERSION}-common" \
  "php${PHP_VERSION}-mysql" \
  "php${PHP_VERSION}-zip" \
  "php${PHP_VERSION}-gd" \
  "php${PHP_VERSION}-mbstring" \
  "php${PHP_VERSION}-curl" \
  "php${PHP_VERSION}-xml" \
  "php${PHP_VERSION}-bcmath" \
  "php${PHP_VERSION}-intl" \
  "php${PHP_VERSION}-readline" \
  "php${PHP_VERSION}-redis" \
  "php${PHP_VERSION}-opcache" \
  mysql-server \
  redis-server \
  supervisor \
  certbot \
  python3-certbot-nginx

if ! command -v composer >/dev/null 2>&1; then
  log "Installing Composer..."
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi

if ! command -v node >/dev/null 2>&1; then
  log "Installing Node.js LTS..."
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt-get install -y nodejs
fi

log "Disabling unnecessary services (if present)..."
for svc in apache2 avahi-daemon; do
  if systemctl list-unit-files | grep -q "^${svc}.service"; then
    systemctl disable --now "${svc}" 2>/dev/null || true
  fi
done

log "Configuring UFW firewall..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

log "Creating deploy user: ${DEPLOY_USER}..."
if ! id "${DEPLOY_USER}" &>/dev/null; then
  useradd -m -s /bin/bash "${DEPLOY_USER}"
fi
usermod -aG www-data "${DEPLOY_USER}"

log "Creating application directories..."
mkdir -p "${APP_DIR}" "${BACKUP_DIR}" /var/log/cariq
chown -R "${DEPLOY_USER}:www-data" "${APP_DIR}" "${BACKUP_DIR}"
chmod -R 775 "${APP_DIR}"

log "Applying PHP production overrides..."
cp "${SCRIPT_DIR}/php/99-cariq-production.ini" "/etc/php/${PHP_VERSION}/fpm/conf.d/99-cariq-production.ini"
cp "${SCRIPT_DIR}/php/99-cariq-production.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/99-cariq-production.ini"
systemctl restart "php${PHP_VERSION}-fpm"

log "Configuring MySQL database and user..."
mysql -e "CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';"
mysql -e "GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

log "Installing Nginx site (HTTP only — SSL after deploy)..."
envsubst '${APP_DOMAIN} ${APP_DIR}' < "${SCRIPT_DIR}/nginx/cariq.conf.template" > "/etc/nginx/sites-available/cariq"
ln -sf "/etc/nginx/sites-available/cariq" "/etc/nginx/sites-enabled/cariq"
rm -f /etc/nginx/sites-enabled/default
sed -i "s|php8.3-fpm.sock|php${PHP_VERSION}-fpm.sock|g" "/etc/nginx/sites-available/cariq"
nginx -t
systemctl enable nginx redis-server mysql supervisor "php${PHP_VERSION}-fpm"
systemctl restart nginx redis-server mysql supervisor "php${PHP_VERSION}-fpm"

log "Installing Supervisor workers..."
cp "${SCRIPT_DIR}/supervisor/cariq-worker.conf" /etc/supervisor/conf.d/cariq-worker.conf
sed -i "s|/var/www/cariq|${APP_DIR}|g" /etc/supervisor/conf.d/cariq-worker.conf
sed -i "s|php8.3|php${PHP_VERSION}|g" /etc/supervisor/conf.d/cariq-worker.conf
supervisorctl reread
supervisorctl update || true

log "Installing cron jobs..."
cp "${SCRIPT_DIR}/cron/cariq" /etc/cron.d/cariq
sed -i "s|/var/www/cariq|${APP_DIR}|g" /etc/cron.d/cariq
sed -i "s|cariq|${DEPLOY_USER}|g" /etc/cron.d/cariq
chmod 644 /etc/cron.d/cariq

log "Installing backup and monitoring scripts..."
install -m 750 "${SCRIPT_DIR}/scripts/backup.sh" /usr/local/bin/cariq-backup
install -m 750 "${SCRIPT_DIR}/scripts/monitor-services.sh" /usr/local/bin/cariq-monitor
install -m 750 "${SCRIPT_DIR}/scripts/verify-production.sh" /usr/local/bin/cariq-verify
sed -i "s|/var/www/cariq|${APP_DIR}|g" /usr/local/bin/cariq-backup /usr/local/bin/cariq-monitor /usr/local/bin/cariq-verify

log "Provisioning complete."
echo ""
echo "Next steps:"
echo "  1. Deploy application:  sudo bash deploy/install-app.sh"
echo "  2. Issue SSL certificate: sudo certbot --nginx -d ${APP_DOMAIN} --email ${ADMIN_EMAIL} --agree-tos --redirect"
echo "  3. Verify:                sudo cariq-verify https://${APP_DOMAIN}"
