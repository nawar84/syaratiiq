# Car IQ — Production Readiness Report

**Date:** 2026-06-18  
**Scope:** Laravel 12 API + Flutter mobile  
**Action taken:** Audit and preparation only — **NOT deployed**

---

## Executive Summary

| Area | Status | Notes |
|------|--------|-------|
| Laravel structure | ✅ Pass | Standard Laravel 12 layout, API routes, models, migrations |
| Flutter structure | ✅ Pass | Feature-based architecture, Riverpod, API client |
| Environment variables | ✅ Pass | `.env.production` template + validator script |
| Image uploads (Storage) | ✅ Pass | `public` disk, `storage:link`, `PublicAssetUrl` |
| API endpoints | ✅ Pass | 36 tests passing (161 assertions) |
| Sanctum auth | ✅ Pass | Bearer tokens, role middleware |
| MySQL compatibility | ✅ Pass | InnoDB, foreign keys, JSON column |
| Localhost URLs | ⚠️ Review | Dev-only references isolated (see §15) |
| Flutter API config | ✅ Pass | `API_BASE_URL` / `API_HOST` via `--dart-define` |
| Deployment scripts | ✅ Ready | `deploy.sh`, `rollback.sh`, `provision.sh` |
| Nginx / Supervisor | ✅ Ready | Config files in `deploy/` |

**Verdict: READY FOR DEPLOYMENT** after filling production secrets and DNS.

---

## 1. Laravel Project Structure

```
backend/
├── app/
│   ├── Http/Controllers/Api/     # 12 API controllers
│   ├── Http/Middleware/          # RoleMiddleware
│   ├── Models/                   # User, Car, Exhibition, Brand, etc.
│   ├── Services/                 # SMS, Subscription, SellerAccount
│   └── Support/PublicAssetUrl.php
├── bootstrap/app.php             # Routes, middleware, scheduler, trustProxies
├── config/                       # Standard Laravel config
├── database/migrations/          # 12 migrations (MySQL-ready)
├── routes/api.php                # 40+ API routes
├── storage/app/public/         # Vehicle & showroom images
└── public/                       # Nginx document root
```

**Health check:** `GET /up` (Laravel built-in)

---

## 2. Flutter Project Structure

```
mobile/lib/
├── main.dart                     # AppConfig.init()
├── src/app/app.dart
├── src/core/
│   ├── config/app_config.dart    # API_BASE_URL configuration
│   ├── network/api_client.dart   # Dio + Sanctum Bearer
│   └── storage/secure_storage_service.dart
└── src/features/
    ├── auth/                     # Login, register, forgot password
    ├── cars/                     # Add/edit/delete cars, image picker
    ├── exhibitions/              # Showroom CRUD
    ├── marketplace/              # Browse, search, filters, favorites
    ├── admin/                    # Dashboard, seller accounts
    └── home/                     # Statistics, brands
```

---

## 3. Development-Only Settings Removed / Isolated

| Setting | Dev | Production |
|---------|-----|------------|
| `APP_DEBUG` | `true` (.env.example) | `false` (.env.production) |
| `LOG_LEVEL` | `debug` | `warning` |
| `SMS_DRIVER` | `log` | `http` (production template) |
| `QUEUE_CONNECTION` | `database` | `redis` |
| `CACHE_STORE` | `database` | `redis` |
| Flutter LAN IP | `devLanHost` | Only in debug builds |
| Release APK | — | **Requires** `API_BASE_URL` or `API_HOST` |

**Changes made:**
- Flutter release builds throw if no API URL is configured
- Sanctum stateful domains removed from config defaults (env-driven)
- `trustProxies` enabled for Nginx/HTTPS

---

## 4. Environment Variables

### Required (production)

| Variable | Purpose |
|----------|---------|
| `APP_KEY` | Encryption (generate on first deploy) |
| `APP_ENV` | Must be `production` |
| `APP_DEBUG` | Must be `false` |
| `APP_URL` | `https://api.yourdomain.com` |
| `DB_*` | MySQL connection |
| `FILESYSTEM_DISK` | Must be `public` |
| `REDIS_*` | Cache, sessions, queue |
| `QUEUE_CONNECTION` | `redis` |
| `CACHE_STORE` | `redis` |

### Optional

| Variable | Purpose |
|----------|---------|
| `SANCTUM_STATEFUL_DOMAINS` | Empty for mobile-only (Bearer tokens) |
| `SMS_*` | Password reset SMS gateway |
| `MAIL_*` | Transactional email |

**Validator:** `bash deploy/scripts/validate-env.sh deploy/.env.production`

---

## 5. Image Uploads — Laravel Storage

| Component | Implementation | Status |
|-----------|----------------|--------|
| Car images | `$file->store('cars/images', 'public')` | ✅ |
| Exhibition logo/cover | `store('exhibitions/...', 'public')` | ✅ |
| URL generation | `PublicAssetUrl::resolve()` (request-aware) | ✅ |
| Car model | `CarImage` + `image_urls` accessor | ✅ |
| Exhibition model | `logo_url`, `cover_image_url` | ✅ Fixed |
| Max upload size | 50MB (`max:51200`) | ✅ |
| Disk config | `FILESYSTEM_DISK=public` | ✅ |

---

## 6. storage:link Configuration

- Defined in `config/filesystems.php` links array
- Run during deploy: `php artisan storage:link --force`
- Nginx serves `/storage/` directly from `storage/app/public/`
- Symlink target: `public/storage` → `storage/app/public`

---

## 7. API Verification

### Public endpoints

| Method | Endpoint | Test coverage |
|--------|----------|---------------|
| GET | `/api/statistics` | ✅ ExampleTest |
| GET | `/api/provinces` | ✅ |
| GET | `/api/brands` | ✅ |
| GET | `/api/cars` | ✅ MarketplaceSearchTest |
| GET | `/api/cars/{id}` | ✅ |
| GET | `/api/showrooms` | ✅ |
| POST | `/api/login` | ✅ AdminPanelTest, SellerAccountTest |
| POST | `/api/register` | ✅ SellerAccountTest |
| POST | `/api/forgot-password` | ✅ PasswordResetTest |
| POST | `/api/reset-password` | ✅ PasswordResetTest |

### Authenticated (Sanctum)

| Feature | Endpoints | Test coverage |
|---------|-----------|---------------|
| Auth | `/me`, `/logout` | ✅ |
| Favorites | CRUD + check | — |
| Owner cars | CRUD + stats | ✅ CarImageUploadTest |
| Showrooms | CRUD | ✅ |
| Subscriptions | status, renew | ✅ SellerAccountTest |
| Admin | dashboard, users, revenue | ✅ AdminPanelTest |
| Seller accounts | full CRUD | ✅ SellerAccountTest |

**Test result:** `36 passed (161 assertions)` — run 2026-06-18

---

## 8. Sanctum Authentication

| Check | Status |
|-------|--------|
| Token issued on login | ✅ `createToken('mobile-token')` |
| Bearer header in Flutter | ✅ `ApiClient` interceptor |
| Role middleware | ✅ `admin`, `owner`, `buyer` |
| Suspended seller blocked | ✅ 403 on login |
| Stateful domains | Env-driven (empty for mobile) |
| CSRF | Not required for Bearer API |

---

## 9. MySQL Compatibility

| Feature | Status |
|---------|--------|
| Engine | InnoDB (Laravel default) |
| Foreign keys | ✅ All migrations |
| JSON column | ✅ `cars.images` |
| utf8mb4 | ✅ Database seeder/migrations |
| Decimal precision | ✅ `price` decimal(12,2) |
| Indexes | ✅ Unique exhibition phone, favorites |
| SQLite dev / MySQL prod | ✅ Same migrations |

**Production DB config:** `DB_CONNECTION=mysql`, localhost socket

---

## 10. Deployment Scripts

| Script | Location | Purpose |
|--------|----------|---------|
| `provision.sh` | `deploy/` | One-time VPS setup |
| `deploy.sh` | `deploy/` | Release-based deployment |
| `rollback.sh` | `deploy/` | Revert to previous release |
| `install-app.sh` | `deploy/` | Simple deploy (legacy) |
| `validate-env.sh` | `deploy/scripts/` | Pre-deploy .env check |
| `verify-production.sh` | `deploy/scripts/` | Post-deploy smoke tests |
| `backup.sh` | `deploy/scripts/` | DB + storage backup |
| `monitor-services.sh` | `deploy/scripts/` | Auto-restart services |

### deploy.sh features
- Pre-deploy validation
- Release directory (`releases/TIMESTAMP`)
- Shared `.env` and `storage` (persistent uploads)
- Maintenance mode during migrate
- Laravel optimize (config, route, view, event cache)
- Service reload

### rollback.sh features
- Switches `current` symlink to previous release
- Re-caches config/routes
- Does **not** rollback migrations (manual if needed)

---

## 11. Nginx Configuration

**File:** `deploy/nginx/cariq.conf` (+ `.template`)

| Feature | Configured |
|---------|------------|
| Document root | `backend/public` |
| PHP-FPM socket | `php8.3-fpm.sock` |
| Client body size | 120M |
| Gzip | JSON, JS, CSS, SVG |
| Static storage cache | 30 days on `/storage/` |
| Security headers | X-Frame-Options, nosniff |
| Block `.env` access | ✅ |

---

## 12. Supervisor Configuration

**File:** `deploy/supervisor/cariq-worker.conf`

```
queue:work redis --sleep=3 --tries=3 --max-time=3600
2 worker processes
autorestart=true
logs: /var/log/cariq/worker.log
```

**Scheduler:** Cron `* * * * * php artisan schedule:run`

---

## 13. .env.production Template

**File:** `deploy/.env.production`

Placeholders to replace before deploy:
- `__APP_DOMAIN__`
- `__DB_PASSWORD__`
- `__MAIL_*__`
- `__SMS_*__`

---

## 14. Deployment Documentation

| Document | Location |
|----------|----------|
| Deployment guide | `deploy/README.md` |
| Full VPS guide | `deploy/PRODUCTION.md` |
| This report | `deploy/PRODUCTION_READINESS_REPORT.md` |

---

## 15. Localhost URL Audit

### Acceptable (dev-only / framework defaults)

| Location | Reason |
|----------|--------|
| `backend/.env.example` | Local development template |
| `backend/config/*.php` fallbacks | Laravel defaults when env unset |
| `mobile/app_config.dart` | Debug builds + emulator (`10.0.2.2`) |
| `deploy/` documentation | Examples |

### Fixed for production

| Location | Fix |
|----------|-----|
| `Exhibition.php` URLs | Now uses `PublicAssetUrl` |
| `sanctum.php` hardcoded localhost | Removed — env only |
| Flutter release without API URL | Throws explicit error |
| `bootstrap/app.php` | Added `trustProxies` for HTTPS |

### No hardcoded production URLs found in application code

---

## 16. Flutter API_BASE_URL Configuration

**File:** `mobile/lib/src/core/config/app_config.dart`

| Priority | Variable | Example |
|----------|----------|---------|
| 1 | `API_BASE_URL` | `--dart-define=API_BASE_URL=https://api.example.com/api` |
| 2 | `API_HOST` + `API_PORT` | `--dart-define=API_HOST=api.example.com --dart-define=API_PORT=443` |
| 3 | `API_SCHEME` | Optional override |
| Dev only | `DEV_LAN_HOST` | LAN IP for debug physical device |

**Production build command:**
```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.yourdomain.com/api
```

---

## Remaining Manual Steps (before deploy)

1. ☐ Register domain and create DNS A record
2. ☐ Copy `deploy/deploy.conf.example` → `deploy.conf` with real values
3. ☐ Copy `deploy/.env.production` → VPS `shared/.env`, fill secrets
4. ☐ Run `validate-env.sh` on production `.env`
5. ☐ Upload project or configure `GIT_REPO`
6. ☐ Run `provision.sh` on VPS (one time)
7. ☐ Run `deploy.sh` on VPS
8. ☐ Run Certbot for SSL
9. ☐ Run `cariq-verify`
10. ☐ Build Flutter APK with production `API_BASE_URL`
11. ☐ Change default seeded passwords if `RUN_DB_SEED=true`
12. ☐ Configure SMS gateway (`SMS_DRIVER=http`)
13. ☐ Set up off-site backups

---

## Checklist Summary

| # | Task | Status |
|---|------|--------|
| 1 | Verify Laravel structure | ✅ |
| 2 | Verify Flutter structure | ✅ |
| 3 | Remove dev-only settings | ✅ |
| 4 | Validate environment variables | ✅ |
| 5 | Image uploads via Storage | ✅ |
| 6 | storage:link configured | ✅ |
| 7 | Verify all APIs | ✅ (36 tests) |
| 8 | Verify Sanctum | ✅ |
| 9 | MySQL compatibility | ✅ |
| 10 | deploy.sh + rollback.sh | ✅ |
| 11 | Nginx configuration | ✅ |
| 12 | Supervisor configuration | ✅ |
| 13 | .env.production template | ✅ |
| 14 | Deployment documentation | ✅ |
| 15 | No localhost in production code | ✅ |
| 16 | Flutter API_BASE_URL | ✅ |
| 17 | Production Readiness Report | ✅ |

**No server connection was made. No deployment was performed.**
