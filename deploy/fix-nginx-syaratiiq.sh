#!/usr/bin/env bash
# Clean Laravel nginx vhost for syaratiiq.com — run on VPS as root
set -euo pipefail

DOMAIN="syaratiiq.com"
WWW="www.syaratiiq.com"
ROOT="/var/www/syaratiiq/backend/public"
CONF="/etc/nginx/sites-available/syaratiiq"

echo "=== Detect active site ==="
grep -rl "${DOMAIN}" /etc/nginx/sites-enabled/ /etc/nginx/sites-available/ 2>/dev/null || true
ls -la /etc/nginx/sites-enabled/

echo "=== Verify document root ==="
test -f "${ROOT}/index.php" || { echo "MISSING: ${ROOT}/index.php"; exit 1; }

echo "=== Write ${CONF} ==="
cat > "${CONF}" <<NGINX
server {
    listen 80;
    listen [::]:80;
    server_name ${DOMAIN} ${WWW};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name ${DOMAIN} ${WWW};

    root ${ROOT};
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/${DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
NGINX

rm -f /etc/nginx/sites-enabled/default
ln -sf "${CONF}" /etc/nginx/sites-enabled/syaratiiq

echo "=== nginx -t ==="
nginx -t

echo "=== reload nginx ==="
systemctl reload nginx

echo "=== verify ==="
curl -sI "https://${DOMAIN}/" | head -15
echo "---"
curl -sk "https://${DOMAIN}/up"
echo
echo "DONE: active=${CONF} root=${ROOT}"
