#!/usr/bin/env bash
# Car IQ — production deployment (run on VPS as root, do NOT run locally)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/deploy.conf"
BACKEND_DIR=""
RELEASES_DIR=""
CURRENT_LINK=""
SHARED_DIR=""
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

log() { echo "[deploy] $*"; }
fail() { echo "[deploy] ERROR: $*" >&2; exit 1; }

require_root() {
  [[ "${EUID}" -eq 0 ]] || fail "Run as root: sudo bash deploy/deploy.sh"
}

load_config() {
  [[ -f "${CONF_FILE}" ]] || fail "Missing ${CONF_FILE}. Copy deploy.conf.example first."
  # shellcheck source=deploy.conf
  source "${CONF_FILE}"
  PHP_VERSION="${PHP_VERSION:-8.3}"
  BACKEND_DIR="${APP_DIR}/backend"
  RELEASES_DIR="${APP_DIR}/releases"
  CURRENT_LINK="${APP_DIR}/current"
  SHARED_DIR="${APP_DIR}/shared"
}

validate_env_file() {
  local env_file="$1"
  [[ -f "${env_file}" ]] || fail "Missing ${env_file}"

  grep -q '^APP_KEY=base64:' "${env_file}" || fail "APP_KEY not set in ${env_file}"
  grep -q '^APP_DEBUG=false' "${env_file}" || fail "APP_DEBUG must be false in production"
  grep -q '^APP_ENV=production' "${env_file}" || fail "APP_ENV must be production"
  grep -q '^FILESYSTEM_DISK=public' "${env_file}" || fail "FILESYSTEM_DISK must be public"
  grep -q '^DB_PASSWORD=.\+' "${env_file}" || fail "DB_PASSWORD is empty"
  grep -qv '__' "${env_file}" || fail "Replace placeholder values (__APP_DOMAIN__, etc.) in ${env_file}"
}

pre_deploy_checks() {
  log "Running pre-deploy checks..."
  command -v php >/dev/null || fail "PHP not installed"
  command -v composer >/dev/null || fail "Composer not installed"
  command -v nginx >/dev/null || fail "Nginx not installed"
  systemctl is-active --quiet "php${PHP_VERSION}-fpm" || fail "php-fpm not running"
  systemctl is-active --quiet nginx || fail "nginx not running"
  validate_env_file "${SHARED_DIR}/.env"
}

backup_current() {
  local backup="${APP_DIR}/backups/pre-deploy-${TIMESTAMP}"
  mkdir -p "${backup}"
  if [[ -L "${CURRENT_LINK}" ]]; then
    cp -a "$(readlink -f "${CURRENT_LINK}")" "${backup}/release"
    echo "${TIMESTAMP}" > "${APP_DIR}/backups/LAST_DEPLOY"
    echo "${backup}" > "${APP_DIR}/backups/LAST_BACKUP_PATH"
  fi
}

deploy_release() {
  local release="${RELEASES_DIR}/${TIMESTAMP}"
  log "Creating release ${release}..."

  mkdir -p "${RELEASES_DIR}" "${SHARED_DIR}/storage"

  if [[ -n "${GIT_REPO:-}" ]]; then
    sudo -u "${DEPLOY_USER}" git clone --branch "${GIT_BRANCH}" "${GIT_REPO}" "${release}"
  elif [[ -d "${APP_DIR}/.git" ]]; then
    rsync -a --exclude releases --exclude shared --exclude backups --exclude current \
      "${APP_DIR}/" "${release}/"
  else
    fail "No GIT_REPO and no project files at ${APP_DIR}"
  fi

  ln -sfn "${SHARED_DIR}/.env" "${release}/backend/.env"
  ln -sfn "${SHARED_DIR}/storage" "${release}/backend/storage"

  pushd "${release}/backend" >/dev/null
  sudo -u "${DEPLOY_USER}" composer install --no-dev --prefer-dist --optimize-autoloader --no-interaction

  sudo -u "${DEPLOY_USER}" php artisan down --retry=60 || true

  sudo -u "${DEPLOY_USER}" php artisan migrate --force

  if [[ "${RUN_DB_SEED:-false}" == "true" ]]; then
    sudo -u "${DEPLOY_USER}" php artisan db:seed --force
  fi

  sudo -u "${DEPLOY_USER}" php artisan storage:link --force

  if [[ -f package.json ]]; then
    sudo -u "${DEPLOY_USER}" npm ci --omit=dev 2>/dev/null || sudo -u "${DEPLOY_USER}" npm install --omit=dev
    sudo -u "${DEPLOY_USER}" npm run build
  fi

  sudo -u "${DEPLOY_USER}" php artisan config:cache
  sudo -u "${DEPLOY_USER}" php artisan route:cache
  sudo -u "${DEPLOY_USER}" php artisan view:cache
  sudo -u "${DEPLOY_USER}" php artisan event:cache
  sudo -u "${DEPLOY_USER}" php artisan optimize

  sudo -u "${DEPLOY_USER}" php artisan up
  popd >/dev/null

  ln -sfn "${release}" "${CURRENT_LINK}"
  echo "${TIMESTAMP}" > "${APP_DIR}/backups/LAST_DEPLOY"
  echo "${release}" > "${APP_DIR}/backups/LAST_RELEASE_PATH"
}

set_permissions() {
  chown -R "${DEPLOY_USER}:www-data" "${APP_DIR}"
  chmod -R 775 "${SHARED_DIR}/storage" "${CURRENT_LINK}/backend/bootstrap/cache"
}

restart_services() {
  systemctl reload "php${PHP_VERSION}-fpm"
  systemctl reload nginx
  supervisorctl reread 2>/dev/null || true
  supervisorctl update 2>/dev/null || true
  supervisorctl restart cariq-worker:* 2>/dev/null || true
}

main() {
  require_root
  load_config
  mkdir -p "${SHARED_DIR}" "${APP_DIR}/backups"

  if [[ ! -f "${SHARED_DIR}/.env" ]]; then
    log "Creating shared .env from template..."
    cp "${SCRIPT_DIR}/.env.production" "${SHARED_DIR}/.env"
    sed -i "s|__APP_DOMAIN__|${APP_DOMAIN}|g" "${SHARED_DIR}/.env"
    sed -i "s|__DB_PASSWORD__|${DB_PASSWORD}|g" "${SHARED_DIR}/.env"
    chown "${DEPLOY_USER}:www-data" "${SHARED_DIR}/.env"
    chmod 640 "${SHARED_DIR}/.env"
    sudo -u "${DEPLOY_USER}" php "${APP_DIR}/backend/artisan" key:generate --force 2>/dev/null \
      || sudo -u "${DEPLOY_USER}" php "${CURRENT_LINK}/backend/artisan" key:generate --force 2>/dev/null \
      || true
  fi

  pre_deploy_checks
  backup_current
  deploy_release
  set_permissions
  restart_services

  log "Deployment complete: ${CURRENT_LINK} -> $(readlink -f "${CURRENT_LINK}")"
  log "Verify: cariq-verify https://${APP_DOMAIN}"
}

main "$@"
