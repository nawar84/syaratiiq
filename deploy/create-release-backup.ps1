# Syarati IQ — complete release backup to Windows Desktop
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Write-Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$desktop = [Environment]::GetFolderPath("Desktop")
$backupRootName = "SyaratiIQ_Backup_$timestamp"
$backupRoot = Join-Path $desktop $backupRootName
$zipPath = "$backupRoot.zip"

$dirs = @(
    "Project_Source",
    "Database",
    "Laravel_ENV",
    "Flutter_Web",
    "Deployment",
    "Documentation"
)
foreach ($d in $dirs) {
    New-Item -ItemType Directory -Force -Path (Join-Path $backupRoot $d) | Out-Null
}

Write-Step "Collecting git metadata"
Push-Location $ProjectRoot
$commitHash = (git rev-parse HEAD).Trim()
$branch = (git branch --show-current).Trim()
$commitSubject = (git log -1 --format="%s").Trim()
Pop-Location

Write-Step "Detecting tool versions"
$phpVersion = (php -v 2>$null | Select-Object -First 1)
Push-Location (Join-Path $ProjectRoot "backend")
$laravelVersion = (php artisan --version 2>$null)
Pop-Location
$flutterVersion = (& "$env:USERPROFILE\flutter\bin\flutter.bat" --version 2>$null | Select-Object -First 1)
if (-not $flutterVersion) {
    $flutterVersion = "Flutter (not found in PATH)"
}
$pubspec = Get-Content (Join-Path $ProjectRoot "mobile\pubspec.yaml") -Raw
$appVersion = if ($pubspec -match 'version:\s*([^\s+#]+)') { $Matches[1] } else { "1.0.0" }

Write-Step "Copying Project_Source (excluding caches and .git)"
$sourceDest = Join-Path $backupRoot "Project_Source"
$robocopyArgs = @(
    $ProjectRoot,
    $sourceDest,
    "/E",
    "/XD", ".git", "node_modules", "vendor", ".dart_tool",
    "/XD", "mobile\build", "mobile\.dart_tool",
    "/XD", "backend\vendor", "backend\node_modules",
    "/XD", "web-dist", ".expo", "dist", "web-build",
    "/XF", ".DS_Store", "Thumbs.db",
    "/NFL", "/NDL", "/NJH", "/NJS", "/NC", "/NS", "/NP"
)
$rc = & robocopy @robocopyArgs
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }

Write-Step "Copying Laravel .env"
$envSrc = Join-Path $ProjectRoot "backend\.env"
if (Test-Path $envSrc) {
    Copy-Item $envSrc (Join-Path $backupRoot "Laravel_ENV\.env") -Force
} else {
    Set-Content (Join-Path $backupRoot "Laravel_ENV\MISSING_ENV.txt") "backend/.env not found at backup time."
}

Write-Step "Copying Flutter web build"
$flutterBuild = Join-Path $ProjectRoot "mobile\build\web"
$flutterDest = Join-Path $backupRoot "Flutter_Web"
if (Test-Path (Join-Path $flutterBuild "index.html")) {
    $rc2 = & robocopy $flutterBuild $flutterDest /E /NFL /NDL /NJH /NJS /NC /NS /NP
    if ($LASTEXITCODE -ge 8) { throw "Flutter web robocopy failed" }
} else {
    Set-Content (Join-Path $flutterDest "BUILD_MISSING.txt") "Run: flutter build web --release --dart-define=API_BASE_URL=https://syaratiiq.com/api"
}

Write-Step "Copying Deployment scripts"
$deploySrc = Join-Path $ProjectRoot "deploy"
$deployDest = Join-Path $backupRoot "Deployment"
if (Test-Path $deploySrc) {
    $rc3 = & robocopy $deploySrc $deployDest /E /XF "vps_deploy_key" /NFL /NDL /NJH /NJS /NC /NS /NP
    if ($LASTEXITCODE -ge 8) { throw "Deployment robocopy failed" }
    Set-Content (Join-Path $deployDest "SECRETS_EXCLUDED.txt") @"
Private SSH keys and askpass credential files are excluded from this backup copy for safety.
They remain only in the local deploy/ folder if present.
"@
}

Write-Step "Attempting local database export"
$dbReadme = Join-Path $backupRoot "Database\README.txt"
$dbDump = Join-Path $backupRoot "Database\syaratiiq_local.sql"
$dumpOk = $false
if (Test-Path $envSrc) {
    $envLines = Get-Content $envSrc
    $dbHost = ($envLines | Where-Object { $_ -match '^DB_HOST=' }) -replace '^DB_HOST=', ''
    $dbPort = ($envLines | Where-Object { $_ -match '^DB_PORT=' }) -replace '^DB_PORT=', ''
    $dbName = ($envLines | Where-Object { $_ -match '^DB_DATABASE=' }) -replace '^DB_DATABASE=', ''
    $dbUser = ($envLines | Where-Object { $_ -match '^DB_USERNAME=' }) -replace '^DB_USERNAME=', ''
    $dbPass = ($envLines | Where-Object { $_ -match '^DB_PASSWORD=' }) -replace '^DB_PASSWORD=', ''
    if (-not $dbPort) { $dbPort = "3306" }
    $mysqldump = "C:\xampp\mysql\bin\mysqldump.exe"
    if ((Test-Path $mysqldump) -and $dbName -and $dbUser) {
        $env:MYSQL_PWD = $dbPass
        & $mysqldump -h $dbHost -P $dbPort -u $dbUser --single-transaction --routines --triggers $dbName 2>$null | Set-Content $dbDump -Encoding UTF8
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
        if ((Test-Path $dbDump) -and (Get-Item $dbDump).Length -gt 100) { $dumpOk = $true }
    }
}
if (-not $dumpOk) {
    Set-Content $dbReadme @"
No local database dump was created automatically.
- Production DB was not exported (manual upload only).
- Ensure XAMPP MySQL is running and backend/.env DB_* values are set to export locally.
"@
} else {
    Set-Content $dbReadme "Local database dump: syaratiiq_local.sql ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
}

$changelog = @(
    "- Flutter web production build with seller profile and image loading fixes",
    "- Seller showroom profile (name, owner, phone, logo edit/delete)",
    "- Exhibition API: remove_logo support",
    "- Web desktop phone frame layout",
    "- Flutter web compatibility (multipart uploads, network images)"
) -join "`n"

Write-Step "Writing Documentation and Version.txt"
$docPath = Join-Path $backupRoot "Documentation\README.md"
@"

# Syarati IQ — Release Backup

| Field | Value |
|-------|-------|
| **Project name** | Syarati IQ (سياراتي IQ) |
| **Backup date** | $(Get-Date -Format "yyyy-MM-dd HH:mm:ss") |
| **Git commit** | ``$commitHash`` |
| **Branch** | ``$branch`` |
| **App version** | $appVersion |
| **Laravel** | $laravelVersion |
| **Flutter** | $flutterVersion |
| **PHP** | $phpVersion |

## Deployment notes

- **Production URL:** https://syaratiiq.com
- **API base:** https://syaratiiq.com/api
- **VPS web root:** /var/www/syaratiiq/backend/public/
- **Flutter deploy:** ``python deploy/deploy-flutter-web.py <ssh-password>``
- **Flutter build:** ``flutter build web --release --dart-define=API_BASE_URL=https://syaratiiq.com/api``
- **Backend cache clear on VPS:** ``php artisan optimize:clear``

## Backup contents

- ``Project_Source/`` — Laravel backend, Flutter mobile, deploy scripts (no vendor/node_modules/.git)
- ``Laravel_ENV/`` — backend ``.env`` snapshot
- ``Flutter_Web/`` — latest ``mobile/build/web`` release build
- ``Deployment/`` — deploy scripts (SSH private keys excluded)
- ``Database/`` — local SQL dump if available

## Restore hints

1. Copy ``Project_Source`` to your dev path and run ``composer install`` in ``backend/``.
2. Restore ``Laravel_ENV/.env`` to ``backend/.env``.
3. Run ``flutter pub get`` in ``mobile/``.
4. Import ``Database/syaratiiq_local.sql`` into MySQL if present.

"@ | Set-Content $docPath -Encoding UTF8

$versionPath = Join-Path $backupRoot "Version.txt"
@"

Syarati IQ Release Backup
Version: $appVersion
Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Commit: $commitHash
Branch: $branch

Changelog:
$changelog

"@ | Set-Content $versionPath -Encoding UTF8

Write-Step "Creating ZIP archive"
if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
Compress-Archive -Path $backupRoot -DestinationPath $zipPath -CompressionLevel Optimal

$folderSize = (Get-ChildItem $backupRoot -Recurse -File | Measure-Object -Property Length -Sum).Sum
$zipSize = (Get-Item $zipPath).Length

Write-Host ""
Write-Host "Backup folder: $backupRoot" -ForegroundColor Green
Write-Host "ZIP file:      $zipPath" -ForegroundColor Green
Write-Host "Folder size:   $([math]::Round($folderSize/1MB, 2)) MB"
Write-Host "ZIP size:      $([math]::Round($zipSize/1MB, 2)) MB"
Write-Host "Commit:        $commitHash"

return @{
    BackupRoot = $backupRoot
    ZipPath = $zipPath
    FolderSizeBytes = $folderSize
    ZipSizeBytes = $zipSize
    CommitHash = $commitHash
    Branch = $branch
    Timestamp = $timestamp
}
