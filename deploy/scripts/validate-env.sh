#!/usr/bin/env bash
# Car IQ — validate production .env before deploy
set -euo pipefail

ENV_FILE="${1:-deploy/.env.production}"

required_keys=(
  APP_NAME APP_ENV APP_KEY APP_DEBUG APP_URL
  DB_CONNECTION DB_HOST DB_DATABASE DB_USERNAME DB_PASSWORD
  FILESYSTEM_DISK QUEUE_CONNECTION CACHE_STORE
  REDIS_HOST SESSION_DRIVER
)

optional_keys=(
  SANCTUM_STATEFUL_DOMAINS SMS_DRIVER MAIL_MAILER
)

fail=0

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "✗ Missing file: ${ENV_FILE}"
  exit 1
fi

echo "=== Environment Validation: ${ENV_FILE} ==="

for key in "${required_keys[@]}"; do
  if grep -q "^${key}=" "${ENV_FILE}"; then
    echo "✓ ${key}"
  else
    echo "✗ Missing required key: ${key}"
    fail=1
  fi
done

if grep -q '^APP_DEBUG=true' "${ENV_FILE}"; then
  echo "✗ APP_DEBUG must be false in production"
  fail=1
else
  echo "✓ APP_DEBUG is not true"
fi

if grep -q '__' "${ENV_FILE}"; then
  echo "✗ Placeholder values remain (contains __)"
  fail=1
else
  echo "✓ No placeholder markers"
fi

if grep -q '^FILESYSTEM_DISK=public' "${ENV_FILE}"; then
  echo "✓ FILESYSTEM_DISK=public"
else
  echo "✗ FILESYSTEM_DISK must be public for image uploads"
  fail=1
fi

if grep -qE '^APP_URL=https://' "${ENV_FILE}"; then
  echo "✓ APP_URL uses HTTPS"
else
  echo "⚠ APP_URL should use https:// in production"
fi

if grep -qE 'localhost|127\.0\.0\.1|192\.168\.' "${ENV_FILE}"; then
  echo "⚠ File contains local/private network references — review before deploy"
fi

echo ""
if [[ "${fail}" -eq 0 ]]; then
  echo "Environment validation passed."
  exit 0
fi

echo "Environment validation failed."
exit 1
