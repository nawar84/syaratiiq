#!/usr/bin/env bash
# Car IQ — daily database + storage backup
set -euo pipefail

APP_DIR="${APP_DIR:-/var/www/cariq}"
BACKEND_DIR="${APP_DIR}/backend"
BACKUP_DIR="${BACKUP_DIR:-/var/backups/cariq}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-14}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
STAMP_DIR="${BACKUP_DIR}/${TIMESTAMP}"

mkdir -p "${STAMP_DIR}"

if [[ -f "${BACKEND_DIR}/.env" ]]; then
  # shellcheck disable=SC1091
  source <(grep -E '^(DB_DATABASE|DB_USERNAME|DB_PASSWORD)=' "${BACKEND_DIR}/.env" | sed 's/^/export /')
fi

DB_NAME="${DB_DATABASE:-car_iq}"
DB_USER="${DB_USERNAME:-car_iq}"
DB_PASS="${DB_PASSWORD:-}"

mysqldump --single-transaction --quick --lock-tables=false \
  -u "${DB_USER}" ${DB_PASS:+-p"${DB_PASS}"} "${DB_NAME}" \
  | gzip > "${STAMP_DIR}/database.sql.gz"

if [[ -d "${BACKEND_DIR}/storage/app/public" ]]; then
  tar -czf "${STAMP_DIR}/storage-public.tar.gz" \
    -C "${BACKEND_DIR}/storage/app" public
fi

find "${BACKUP_DIR}" -mindepth 1 -maxdepth 1 -type d -mtime +"${RETENTION_DAYS}" -exec rm -rf {} +

echo "[backup] Completed ${STAMP_DIR}"
