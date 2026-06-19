"""Deploy Flutter web build to VPS, replacing Expo frontend."""
from __future__ import annotations

import os
import sys
from pathlib import Path

import paramiko

HOST = "207.180.208.172"
USER = "root"
REMOTE_PUBLIC = "/var/www/syaratiiq/backend/public"

ROOT = Path(__file__).resolve().parents[1]
FLUTTER_WEB = ROOT / "mobile" / "build" / "web"

# Frontend artifacts to remove before uploading Flutter web build.
REMOVE_ITEMS = [
    "_expo",
    "assets",
    "canvaskit",
    "icons",
    "index.html",
    "metadata.json",
    "favicon.ico",
    "favicon.png",
    "flutter.js",
    "flutter_bootstrap.js",
    "flutter_service_worker.js",
    "main.dart.js",
    "manifest.json",
    "version.json",
    ".last_build_id",
]


def connect(password: str) -> paramiko.SSHClient:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    client.connect(
        HOST,
        username=USER,
        password=password,
        timeout=30,
        banner_timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )
    return client


def sftp_put_dir(sftp: paramiko.SFTPClient, local: Path, remote: str) -> None:
    if local.is_file():
        sftp.put(str(local), remote)
        return
    try:
        sftp.mkdir(remote)
    except OSError:
        pass
    for item in local.iterdir():
        sftp_put_dir(sftp, item, f"{remote}/{item.name}")


def run(client: paramiko.SSHClient, cmd: str) -> tuple[int, str, str]:
    _, stdout, stderr = client.exec_command(cmd, timeout=300)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    return stdout.channel.recv_exit_status(), out, err


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: deploy-flutter-web.py <ssh-password>", file=sys.stderr)
        return 2

    if not (FLUTTER_WEB / "index.html").is_file():
        print(f"Missing Flutter build: {FLUTTER_WEB}", file=sys.stderr)
        return 1

    pwd = sys.argv[1]
    client = connect(pwd)
    print(f"Connected to {HOST}")
    print(f"Local build: {FLUTTER_WEB}")

    remove_cmds = " && ".join(
        f"rm -rf {REMOTE_PUBLIC}/{item}" for item in REMOVE_ITEMS
    )
    cleanup_cmd = f"{remove_cmds} 2>/dev/null; true"
    print(f"\n>>> {cleanup_cmd}")
    code, out, err = run(client, cleanup_cmd)
    print(out.strip())
    if err.strip():
        print(err.strip())
    if code != 0:
        client.close()
        return code

    sftp = client.open_sftp()
    for name in os.listdir(FLUTTER_WEB):
        local = FLUTTER_WEB / name
        remote = f"{REMOTE_PUBLIC}/{name}"
        print(f"Upload {local.name} -> {remote}")
        sftp_put_dir(sftp, local, remote)
    sftp.close()

    verify_cmds = [
        f"chown -R www-data:www-data {REMOTE_PUBLIC} 2>/dev/null || true",
        "cd /var/www/syaratiiq/backend && php artisan route:clear && php artisan optimize:clear",
        "test -f /var/www/syaratiiq/backend/public/index.php && echo LARAVEL_INDEX_OK",
        "test -f /var/www/syaratiiq/backend/public/main.dart.js && echo FLUTTER_JS_OK",
        "test ! -d /var/www/syaratiiq/backend/public/_expo && echo EXPO_REMOVED_OK",
        "grep -o '<title>[^<]*</title>' /var/www/syaratiiq/backend/public/index.html",
        "grep -q 'flutter_bootstrap.js' /var/www/syaratiiq/backend/public/index.html && echo FLUTTER_HTML_OK",
        "grep -q 'https://syaratiiq.com/api' /var/www/syaratiiq/backend/public/main.dart.js && echo API_URL_OK",
        "curl -sk -o /dev/null -w 'HOME=%{http_code} API=%{http_code} UP=%{http_code}' https://syaratiiq.com/ https://syaratiiq.com/api/statistics https://syaratiiq.com/up",
    ]

    for cmd in verify_cmds:
        print(f"\n>>> {cmd}")
        code, out, err = run(client, cmd)
        print(out.strip())
        if err.strip():
            print(err.strip())

    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
