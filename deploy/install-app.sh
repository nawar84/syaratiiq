#!/usr/bin/env bash
# Car IQ — deploy / update Laravel backend on the VPS
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/deploy.conf"

if [[ ! -f "${CONF_FILE}" ]]; then
  echo "Missing ${CONF_FILE}"
  exit 1
fi

# shellcheck source=deploy.conf
source "${CONF_FILE}"

PHP_VERSION="${PHP_VERSION:-8.3}"
BACKEND_DIR="${APP_DIR}/backend"
ENV_FILE="${BACKEND_DIR}/.env"

log() { echo "[install-app] $*"; }

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run as root: sudo bash deploy/install-app.sh"
  exit 1
fi

log "Fetching application code..."
if [[ -n "${GIT_REPO}" ]]; then
  if [[ ! -d "${APP_DIR}/.git" ]]; then
    sudo -u "${DEPLOY_USER}" git clone --branch "${GIT_BRANCH}" "${GIT_REPO}" "${APP_DIR}"
  else
    sudo -u "${DEPLOY_USER}" git -C "${APP_DIR}" fetch origin
    sudo -u "${DEPLOY_USER}" git -C "${APP_DIR}" checkout "${GIT_BRANCH}"
    sudo -u "${DEPLOY_USER}" git -C "${APP_DIR}" pull origin "${GIT_BRANCH}"
  fi
else
  if [[ ! -f "${BACKEND_DIR}/artisan" ]]; then
    echo "No GIT_REPO set and ${BACKEND_DIR}/artisan not found."
    echo "Upload the project to ${APP_DIR} first (rsync/scp), then re-run."
    exit 1
  fi
fi

log "Installing Composer dependencies (production)..."
sudo -u "${DEPLOY_USER}" composer install \
  --no-dev \
  --prefer-dist \
  --optimize-autoloader \
  --no-interaction \
  --working-dir="${BACKEND_DIR}"

if [[ ! -f "${ENV_FILE}" ]]; then
  log "Creating .env from production template..."
  cp "${SCRIPT_DIR}/env.production.example" "${ENV_FILE}"
  sed -i "s|__APP_DOMAIN__|${APP_DOMAIN}|g" "${ENV_FILE}"
  sed -i "s|DB_DATABASE=.*|DB_DATABASE=${DB_NAME}|" "${ENV_FILE}"
  sed -i "s|DB_USERNAME=.*|DB_USERNAME=${DB_USER}|" "${ENV_FILE}"
  sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${DB_PASSWORD}|" "${ENV_FILE}"
  chown "${DEPLOY_USER}:www-data" "${ENV_FILE}"
  chmod 640 "${ENV_FILE}"
fi

log "Generating app key if missing..."
if ! grep -q '^APP_KEY=base64:' "${ENV_FILE}"; then
  sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" key:generate --force
fi

log "Running migrations..."
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" migrate --force

if [[ "${RUN_DB_SEED}" == "true" ]]; then
  log "Seeding database (demo data)..."
  sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" db:seed --force
fi

log "Linking public storage for vehicle images..."
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" storage:link --force

log "Building frontend assets (if package.json exists)..."
if [[ -f "${BACKEND_DIR}/package.json" ]]; then
  pushd "${BACKEND_DIR}" >/dev/null
  sudo -u "${DEPLOY_USER}" npm ci --omit=dev 2>/dev/null || sudo -u "${DEPLOY_USER}" npm install --omit=dev
  sudo -u "${DEPLOY_USER}" npm run build
  popd >/dev/null
fi

log "Optimizing Laravel for production..."
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" config:cache
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" route:cache
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" view:cache
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" event:cache
sudo -u "${DEPLOY_USER}" php "${BACKEND_DIR}/artisan" optimize

log "Setting permissions..."
chown -R "${DEPLOY_USER}:www-data" "${APP_DIR}"
find "${BACKEND_DIR}/storage" "${BACKEND_DIR}/bootstrap/cache" -type d -exec chmod 775 {} \;
find "${BACKEND_DIR}/storage" "${BACKEND_DIR}/bootstrap/cache" -type f -exec chmod 664 {} \;

log "Restarting services..."
systemctl reload "php${PHP_VERSION}-fpm"
systemctl reload nginx
supervisorctl reread
supervisorctl update
supervisorctl restart cariq-worker:* || supervisorctl start cariq-worker:*

log "Application deployed to ${BACKEND_DIR}"
echo "Verify: sudo cariq-verify https://${APP_DOMAIN}"
