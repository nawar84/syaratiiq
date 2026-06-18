# Car IQ Production Deployment

**Status:** Ready for deployment (prepared, not deployed)

## Prerequisites

- Fresh Ubuntu VPS (22.04 or 24.04)
- Domain DNS pointing to VPS (`api.yourdomain.com`)
- SSH access as root

## Files

| File | Purpose |
|------|---------|
| `deploy.conf.example` | Server configuration (copy → `deploy.conf`) |
| `.env.production` | Laravel production environment template |
| `provision.sh` | One-time server setup |
| `deploy.sh` | Zero-downtime release deployment |
| `rollback.sh` | Revert to previous release |
| `nginx/cariq.conf` | Nginx virtual host |
| `supervisor/cariq-worker.conf` | Queue workers |
| `scripts/validate-env.sh` | Pre-deploy .env validation |
| `scripts/verify-production.sh` | Post-deploy smoke tests |
| `PRODUCTION_READINESS_REPORT.md` | Full audit report |

## Deployment Order (when ready)

```bash
# 1. One-time server setup
cp deploy/deploy.conf.example deploy/deploy.conf
nano deploy/deploy.conf
sudo bash deploy/provision.sh

# 2. Prepare shared .env on server
cp deploy/.env.production /var/www/cariq/shared/.env
nano /var/www/cariq/shared/.env
bash deploy/scripts/validate-env.sh /var/www/cariq/shared/.env

# 3. Deploy application
sudo bash deploy/deploy.sh

# 4. SSL
sudo certbot --nginx -d api.yourdomain.com --redirect

# 5. Verify
sudo cariq-verify https://api.yourdomain.com
```

## Flutter Production Build

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

## Rollback

```bash
sudo bash deploy/rollback.sh
```

See `PRODUCTION_READINESS_REPORT.md` for the complete audit.
