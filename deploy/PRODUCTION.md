# Car IQ — Production VPS Deployment Guide

Complete production setup for **Laravel 12 API + Flutter mobile** on a fresh Ubuntu VPS.

---

## Quick Start (on the VPS)

```bash
# 1. Upload project or clone repo
cd /var/www/cariq   # or upload via rsync/scp

# 2. Configure deployment variables
cp deploy/deploy.conf.example deploy/deploy.conf
nano deploy/deploy.conf

# 3. Provision server (run once as root)
sudo bash deploy/provision.sh

# 4. Deploy Laravel application
sudo bash deploy/install-app.sh

# 5. SSL (Let's Encrypt + HTTPS redirect)
sudo certbot --nginx -d api.yourdomain.com --email you@domain.com --agree-tos --redirect

# 6. Verify everything
sudo cariq-verify https://api.yourdomain.com
```

---

## Deploy Code Without Git

From your **local machine**:

```powershell
# Sync entire project to VPS (exclude dev artifacts)
rsync -avz --exclude node_modules --exclude vendor --exclude .git `
  "c:\xampp\htdocs\car iq\" `
  cariq@YOUR_VPS_IP:/var/www/cariq/
```

Then on VPS: `sudo bash deploy/install-app.sh`

---

## Flutter Production Build

Build the mobile app pointing to your production API:

```bash
flutter build apk --release \
  --dart-define=API_HOST=api.yourdomain.com \
  --dart-define=API_PORT=443
```

Update `app_config.dart` to use `https` when port is 443 (manual step below).

---

## Production Report

### ✓ Installed Software

| Component | Version / Package |
|-----------|-------------------|
| Ubuntu | Updated (`apt upgrade`) |
| Nginx | Latest from Ubuntu repos |
| PHP | 8.3-FPM + CLI (Ondřej Surý PPA) |
| PHP Extensions | mysql, zip, gd, mbstring, curl, xml, bcmath, intl, redis, opcache, readline |
| Composer | `/usr/local/bin/composer` |
| MySQL Server | 8.x |
| Redis | Latest |
| Supervisor | Queue workers |
| Node.js | LTS (NodeSource) |
| npm | Bundled with Node.js |
| Certbot | `python3-certbot-nginx` |
| Git, curl, unzip | System packages |

### ✓ Configured Services

| Service | Purpose |
|---------|---------|
| **UFW** | Deny incoming default; allow SSH + HTTP + HTTPS |
| **MySQL** | Database `car_iq`, user `car_iq`, localhost only |
| **Nginx** | Virtual host → `backend/public`, gzip, 120MB uploads, `/storage` caching |
| **PHP 8.3-FPM** | OPcache, 100MB uploads, production timezone |
| **Redis** | Cache, sessions, queue backend |
| **Supervisor** | 2× `queue:work redis` workers |
| **Cron** | Laravel scheduler (every minute) |
| **Cron** | Daily DB + storage backup (02:30) |
| **Cron** | Service monitor (every 5 min) |
| **SSL** | Certbot + forced HTTPS (manual certbot step) |
| **Backups** | `/var/backups/cariq/` — 14-day retention |
| **Permissions** | `cariq:www-data`, 775 on storage & bootstrap/cache |
| **Laravel optimize** | config, route, view, event cache + autoloader |

### ✓ Laravel Production Checklist

- [x] `composer install --no-dev --optimize-autoloader`
- [x] `php artisan key:generate`
- [x] `php artisan migrate --force`
- [x] `php artisan storage:link` (vehicle images)
- [x] `FILESYSTEM_DISK=public`
- [x] `APP_DEBUG=false`
- [x] `QUEUE_CONNECTION=redis`
- [x] `CACHE_STORE=redis`
- [x] Scheduler registered in `bootstrap/app.php`

### ✓ Verification Endpoints

Run `sudo cariq-verify https://api.yourdomain.com`:

| Check | Endpoint |
|-------|----------|
| Health | `GET /up` |
| Statistics | `GET /api/statistics` |
| Provinces | `GET /api/provinces` |
| Brands | `GET /api/brands` |
| Cars CRUD | `GET /api/cars` |
| Showrooms | `GET /api/showrooms` |
| Sanctum login | `POST /api/login` |
| Auth token | `GET /api/me` |
| Storage symlink | `public/storage` → `storage/app/public` |
| Queue workers | Supervisor `cariq-worker:*` |
| Services | nginx, php-fpm, mysql, redis, supervisor |

---

## Remaining Manual Steps

1. **DNS** — Point `A` record for `api.yourdomain.com` → VPS public IP.

2. **Edit `deploy/deploy.conf`** — Set real domain, DB password, admin email.

3. **Upload or clone code** — No Git remote configured yet; use `rsync` or add `GIT_REPO` to config.

4. **Run Certbot** after DNS propagates:
   ```bash
   sudo certbot --nginx -d api.yourdomain.com --email you@domain.com --agree-tos --redirect
   ```

5. **Change default passwords** — If `RUN_DB_SEED=true`, change admin/seller passwords immediately:
   - Admin: `admin` / `1234`
   - Seller: `1234` / `1234`

6. **Flutter HTTPS** — Update `mobile/lib/src/core/config/app_config.dart`:
   ```dart
   apiBaseUrl = port == '443'
       ? 'https://$host/api'
       : 'http://$host:$port/api';
   ```
   Then rebuild APK with `--dart-define=API_HOST=api.yourdomain.com --dart-define=API_PORT=443`.

7. **SMS gateway** — Set `SMS_DRIVER=http`, `SMS_API_KEY`, `SMS_HTTP_URL` in production `.env`.

8. **MySQL hardening** (recommended):
   ```bash
   sudo mysql_secure_installation
   ```

9. **Fail2ban** (recommended):
   ```bash
   sudo apt install fail2ban -y
   ```

10. **Off-site backups** — Copy `/var/backups/cariq/` to S3 or another server.

11. **Monitoring** — Add UptimeRobot / Better Stack for `/up` endpoint.

12. **GitHub Actions** (optional) — Automate `install-app.sh` on push to `master`.

---

## File Structure

```
deploy/
├── deploy.conf.example      # Copy → deploy.conf
├── provision.sh             # Server setup (once)
├── install-app.sh           # Deploy / update app
├── env.production.example   # Laravel .env template
├── PRODUCTION.md            # This guide
├── nginx/cariq.conf.template
├── php/99-cariq-production.ini
├── supervisor/cariq-worker.conf
├── cron/cariq
└── scripts/
    ├── backup.sh
    ├── monitor-services.sh
    └── verify-production.sh
```

---

## Troubleshooting

| Issue | Fix |
|-------|-----|
| 502 Bad Gateway | `sudo systemctl status php8.3-fpm nginx` |
| Images 404 | `php artisan storage:link` + check Nginx `/storage/` alias |
| Upload too large | Nginx `client_max_body_size` + PHP `upload_max_filesize` |
| Queue not processing | `sudo supervisorctl status cariq-worker:*` |
| Sanctum 401 | Check `APP_URL`, CORS, token header |
| Config cached after .env change | `php artisan config:clear && php artisan config:cache` |

---

## Security Notes

- Never commit `deploy/deploy.conf` or production `.env`
- Use strong `DB_PASSWORD` and rotate after first deploy
- Keep `APP_DEBUG=false` in production
- Restrict MySQL to `localhost`
- Renew SSL automatically via certbot timer
