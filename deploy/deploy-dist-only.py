"""Upload existing web build (dist or web-dist) to VPS public root only."""
from __future__ import annotations

import hashlib
import os
import sys
from pathlib import Path

import paramiko

HOST = "207.180.208.172"
USER = "root"
REMOTE_PUBLIC = "/var/www/syaratiiq/backend/public"

ROOT = Path(__file__).resolve().parents[1]
SPA_NAMES = {"index.html", "favicon.ico", "metadata.json", "_expo", "assets"}


def resolve_build_dir() -> Path:
    for candidate in (ROOT / "dist", ROOT / "web-dist"):
        if candidate.is_dir() and (candidate / "index.html").is_file():
            return candidate
    raise SystemExit(
        "No deployable build found. Expected dist/index.html or web-dist/index.html under "
        f"{ROOT}"
    )


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
    _, stdout, stderr = client.exec_command(cmd, timeout=180)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    return stdout.channel.recv_exit_status(), out, err


def file_hash(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()[:16]


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: deploy-dist-only.py <ssh-password>", file=sys.stderr)
        return 2

    build_dir = resolve_build_dir()
    print(f"Local build source: {build_dir}")

    index_html = build_dir / "index.html"
    js_files = list((build_dir / "_expo" / "static" / "js" / "web").glob("index-*.js"))
    if not js_files:
        print("Missing Expo JS bundle in build output", file=sys.stderr)
        return 1

    bundle = js_files[0]
    local_bundle_hash = bundle.name.replace("index-", "").replace(".js", "")
    print(f"Local bundle: {bundle.name} ({file_hash(bundle)})")

    pwd = sys.argv[1]
    client = connect(pwd)
    print(f"Connected to {HOST}")

    cleanup_cmd = (
        f"cd {REMOTE_PUBLIC} && "
        "rm -rf _expo assets && "
        "rm -f index.html favicon.ico metadata.json"
    )
    print(f"\n>>> {cleanup_cmd}")
    code, out, err = run(client, cleanup_cmd)
    print(out.strip())
    if err.strip():
        print(err.strip())
    if code != 0:
        client.close()
        return code

    sftp = client.open_sftp()
    for name in os.listdir(build_dir):
        local = build_dir / name
        remote = f"{REMOTE_PUBLIC}/{name}"
        print(f"Upload {local.name} -> {remote}")
        sftp_put_dir(sftp, local, remote)
    sftp.close()

    verify_cmds = [
        f"chown -R www-data:www-data {REMOTE_PUBLIC}/index.html {REMOTE_PUBLIC}/_expo {REMOTE_PUBLIC}/assets {REMOTE_PUBLIC}/favicon.ico {REMOTE_PUBLIC}/metadata.json 2>/dev/null || true",
        "cd /var/www/syaratiiq/backend && php artisan route:clear && php artisan optimize:clear",
        "curl -sI https://syaratiiq.com/ | head -8",
        "grep -o 'index-[a-f0-9]*\\.js' /var/www/syaratiiq/backend/public/index.html | head -1",
        "test -f /var/www/syaratiiq/backend/public/assets/mobile/assets/images/hero_toyota_land_cruiser*.png && echo HERO_OK || echo HERO_MISSING",
        "grep -q '+10,000' /var/www/syaratiiq/backend/public/_expo/static/js/web/index-*.js && echo STATS_OK || echo STATS_MISSING",
        "grep -q 'toyota\\|bmw\\|hyundai' /var/www/syaratiiq/backend/public/_expo/static/js/web/index-*.js && echo BRANDS_OK || echo BRANDS_MISSING",
        "grep -q 'الرئيسية' /var/www/syaratiiq/backend/public/_expo/static/js/web/index-*.js && echo NAV_OK || echo NAV_MISSING",
        "curl -sk -o /dev/null -w 'HOME=%{http_code} UP=%{http_code}' https://syaratiiq.com/ https://syaratiiq.com/up",
    ]

    remote_hash = None
    for cmd in verify_cmds:
        print(f"\n>>> {cmd}")
        code, out, err = run(client, cmd)
        print(out.strip())
        if err.strip():
            print(err.strip())
        if "grep -o 'index-" in cmd and out.strip():
            remote_hash = out.strip().replace("index-", "").replace(".js", "")

    client.close()

    print("\n=== DEPLOY SUMMARY ===")
    print(f"Source folder : {build_dir}")
    print(f"Local bundle  : index-{local_bundle_hash}.js")
    if remote_hash:
        print(f"Remote bundle : index-{remote_hash}.js")
        print(f"Bundle match  : {'YES' if remote_hash == local_bundle_hash else 'NO'}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
