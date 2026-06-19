"""Upload Expo web build + Laravel SPA route to VPS."""
from __future__ import annotations

import os
import sys
from pathlib import Path

import paramiko

HOST = "207.180.208.172"
USER = "root"
REMOTE_PUBLIC = "/var/www/syaratiiq/backend/public"
REMOTE_WEB_PHP = "/var/www/syaratiiq/backend/routes/web.php"

ROOT = Path(__file__).resolve().parents[1]
WEB_DIST = ROOT / "web-dist"
WEB_PHP = ROOT / "backend" / "routes" / "web.php"


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
    _, stdout, stderr = client.exec_command(cmd, timeout=120)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    return stdout.channel.recv_exit_status(), out, err


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: deploy-frontend.py <ssh-password>", file=sys.stderr)
        return 2

    if not WEB_DIST.is_dir():
        print(f"Missing build output: {WEB_DIST}", file=sys.stderr)
        return 1
    if not WEB_PHP.is_file():
        print(f"Missing route file: {WEB_PHP}", file=sys.stderr)
        return 1

    pwd = sys.argv[1]
    client = connect(pwd)
    print(f"Connected to {HOST}")

    sftp = client.open_sftp()
    for name in os.listdir(WEB_DIST):
        local = WEB_DIST / name
        remote = f"{REMOTE_PUBLIC}/{name}"
        print(f"Upload {local.name} -> {remote}")
        sftp_put_dir(sftp, local, remote)

    print(f"Upload web.php -> {REMOTE_WEB_PHP}")
    sftp.put(str(WEB_PHP), REMOTE_WEB_PHP)
    sftp.close()

    cmds = [
        "chown -R www-data:www-data /var/www/syaratiiq/backend/public/index.html /var/www/syaratiiq/backend/public/_expo /var/www/syaratiiq/backend/routes/web.php 2>/dev/null || true",
        "cd /var/www/syaratiiq/backend && php artisan route:clear && php artisan optimize:clear",
        "curl -sI https://syaratiiq.com/ | head -12",
        "curl -sk https://syaratiiq.com/ | grep -oE '<title>[^<]+</title>|سيارتي|car-iq-app|Let\\x27s get started' | head -5",
        "curl -sk -o /dev/null -w 'UP=%{http_code} API=%{http_code}' https://syaratiiq.com/up https://syaratiiq.com/api/statistics",
    ]
    for cmd in cmds:
        print(f"\n>>> {cmd}")
        code, out, err = run(client, cmd)
        print(out.strip())
        if err.strip():
            print(err.strip())
        if code != 0 and "curl" not in cmd:
            client.close()
            return code

    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
