#!/usr/bin/env bash
# Car IQ — production smoke tests
set -euo pipefail

BASE_URL="${1:-https://api.example.com}"
API="${BASE_URL%/}/api"
FAIL=0

check() {
  local name="$1"
  local url="$2"
  local expect="${3:-200}"
  local code
  code="$(curl -sk -o /tmp/cariq-verify-body -w '%{http_code}' "${url}")"
  if [[ "${code}" != "${expect}" ]]; then
    echo "✗ ${name} — HTTP ${code} (expected ${expect})"
    FAIL=1
  else
    echo "✓ ${name} — HTTP ${code}"
  fi
}

echo "=== Car IQ Production Verification ==="
echo "Base: ${BASE_URL}"
echo ""

check "Health (/up)" "${BASE_URL%/}/up"
check "Statistics API" "${API}/statistics"
check "Provinces API" "${API}/provinces"
check "Brands API" "${API}/brands"
check "Cars list API" "${API}/cars"
check "Showrooms API" "${API}/showrooms"

echo ""
echo "--- Login (Sanctum) ---"
LOGIN_CODE="$(curl -sk -o /tmp/cariq-login.json -w '%{http_code}' \
  -X POST "${API}/login" \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"1234"}')"

if [[ "${LOGIN_CODE}" == "200" ]] && grep -q '"token"' /tmp/cariq-login.json 2>/dev/null; then
  echo "✓ Sanctum login — token issued"
  TOKEN="$(python3 -c "import json; print(json.load(open('/tmp/cariq-login.json')).get('token',''))" 2>/dev/null || true)"
  if [[ -n "${TOKEN}" ]]; then
    ME_CODE="$(curl -sk -o /dev/null -w '%{http_code}' \
      -H "Authorization: Bearer ${TOKEN}" \
      -H 'Accept: application/json' \
      "${API}/me")"
    if [[ "${ME_CODE}" == "200" ]]; then
      echo "✓ Sanctum /me — authenticated"
    else
      echo "✗ Sanctum /me — HTTP ${ME_CODE}"
      FAIL=1
    fi
  fi
else
  echo "✗ Sanctum login — HTTP ${LOGIN_CODE} (seed admin or fix credentials)"
  FAIL=1
fi

echo ""
echo "--- Storage symlink ---"
APP_DIR="${APP_DIR:-/var/www/cariq}"
if [[ -L "${APP_DIR}/backend/public/storage" ]]; then
  echo "✓ storage:link symlink exists"
else
  echo "✗ storage:link missing — run: php artisan storage:link"
  FAIL=1
fi

echo ""
echo "--- Services ---"
for svc in nginx php8.3-fpm mysql redis-server supervisor; do
  if systemctl is-active --quiet "${svc}" 2>/dev/null; then
    echo "✓ ${svc} running"
  else
    echo "✗ ${svc} not running"
    FAIL=1
  fi
done

if supervisorctl status cariq-worker:* 2>/dev/null | grep -q RUNNING; then
  echo "✓ queue workers running"
else
  echo "✗ queue workers not running"
  FAIL=1
fi

echo ""
if [[ "${FAIL}" -eq 0 ]]; then
  echo "All checks passed."
  exit 0
fi

echo "Some checks failed — review logs in /var/log/nginx/ and /var/log/cariq/"
exit 1
