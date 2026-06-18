#!/usr/bin/env bash
# Car IQ — restart failed core services
set -euo pipefail

PHP_VERSION="${PHP_VERSION:-8.3}"
SERVICES=(nginx "php${PHP_VERSION}-fpm" mysql redis-server supervisor)

for svc in "${SERVICES[@]}"; do
  if ! systemctl is-active --quiet "${svc}"; then
    echo "[monitor] ${svc} is down — restarting"
    systemctl restart "${svc}" || true
  fi
done

if command -v supervisorctl >/dev/null 2>&1; then
  if ! supervisorctl status cariq-worker:* 2>/dev/null | grep -q RUNNING; then
    echo "[monitor] queue workers not running — restarting"
    supervisorctl restart cariq-worker:* || supervisorctl start cariq-worker:* || true
  fi
fi

echo "[monitor] OK $(date -Is)"
