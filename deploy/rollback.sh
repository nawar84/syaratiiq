#!/usr/bin/env bash
# Car IQ — rollback to previous release (run on VPS as root)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="${SCRIPT_DIR}/deploy.conf"

log() { echo "[rollback] $*"; }
fail() { echo "[rollback] ERROR: $*" >&2; exit 1; }

require_root() {
  [[ "${EUID}" -eq 0 ]] || fail "Run as root: sudo bash deploy/rollback.sh"
}

load_config() {
  [[ -f "${CONF_FILE}" ]] || fail "Missing ${CONF_FILE}"
  # shellcheck source=deploy.conf
  source "${CONF_FILE}"
  PHP_VERSION="${PHP_VERSION:-8.3}"
}

find_previous_release() {
  local current="${APP_DIR}/current"
  local releases="${APP_DIR}/releases"
  local current_release

  [[ -L "${current}" ]] || fail "No current release symlink at ${current}"
  current_release="$(basename "$(readlink -f "${current}")")"

  mapfile -t all_releases < <(ls -1 "${releases}" 2>/dev/null | sort)
  [[ "${#all_releases[@]}" -ge 2 ]] || fail "No previous release found in ${releases}"

  local prev=""
  for (( i=${#all_releases[@]}-1; i>=0; i-- )); do
    if [[ "${all_releases[$i]}" != "${current_release}" ]]; then
      prev="${all_releases[$i]}"
      break
    fi
  done

  [[ -n "${prev}" ]] || fail "Could not determine previous release"
  echo "${releases}/${prev}"
}

rollback() {
  local previous
  previous="$(find_previous_release)"
  log "Rolling back to ${previous}..."

  sudo -u "${DEPLOY_USER}" php "${previous}/backend/artisan" down --retry=60 || true

  ln -sfn "${previous}" "${APP_DIR}/current"

  pushd "${previous}/backend" >/dev/null
  sudo -u "${DEPLOY_USER}" php artisan config:cache
  sudo -u "${DEPLOY_USER}" php artisan route:cache
  sudo -u "${DEPLOY_USER}" php artisan view:cache
  sudo -u "${DEPLOY_USER}" php artisan optimize
  sudo -u "${DEPLOY_USER}" php artisan up
  popd >/dev/null

  systemctl reload "php${PHP_VERSION}-fpm"
  systemctl reload nginx
  supervisorctl restart cariq-worker:* 2>/dev/null || true

  echo "$(basename "${previous}")" > "${APP_DIR}/backups/LAST_ROLLBACK"
  log "Rollback complete. Active: ${previous}"
}

main() {
  require_root
  load_config
  rollback
  log "Verify: cariq-verify https://${APP_DOMAIN}"
}

main "$@"
