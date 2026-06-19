#!/usr/bin/env python3
"""Replace active nginx vhost for syaratiiq.com with clean Laravel config."""
from __future__ import annotations

import sys
from pathlib import Path

import paramiko

HOST = "207.180.208.172"
USER = "root"
DOMAIN = "syaratiiq.com"
WWW = "www.syaratiiq.com"
ROOT = "/var/www/syaratiiq/backend/public"

NGINX_CONF = f"""server {{
    listen 80;
    listen [::]:80;
    server_name {DOMAIN} {WWW};
    return 301 https://$host$request_uri;
}}

server {{
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name {DOMAIN} {WWW};

    root {ROOT};
    index index.php index.html;

    ssl_certificate /etc/letsencrypt/live/{DOMAIN}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/{DOMAIN}/privkey.pem;
    include /etc/letsencrypt/options-ssl-nginx.conf;
    ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem;

    location / {{
        try_files $uri $uri/ /index.php?$query_string;
    }}

    location ~ \\.php$ {{
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:/run/php/php8.3-fpm.sock;
    }}

    location ~ /\\.(?!well-known).* {{
        deny all;
    }}
}}
"""


def load_password() -> str:
    for name in ("askpass.cmd", "askpass_qnj.cmd", "askpass.py"):
        path = Path(__file__).resolve().parent / name
        if not path.is_file():
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        for line in text.splitlines():
            line = line.strip()
            if line.lower().startswith("echo "):
                return line[5:].strip()
            if name.endswith(".py") and "write(" in text:
                import re

                m = re.search(r'write\("([^"]+)"\)', text)
                if m:
                    return m.group(1)
    return ""


def connect() -> paramiko.SSHClient:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    key_path = Path(__file__).resolve().parent / "vps_deploy_key"
    if key_path.is_file():
        try:
            key = paramiko.Ed25519Key.from_private_key_file(str(key_path))
            client.connect(
                HOST,
                username=USER,
                pkey=key,
                timeout=30,
                banner_timeout=30,
                allow_agent=False,
                look_for_keys=False,
            )
            return client
        except paramiko.AuthenticationException:
            pass
    pwd = load_password()
    if not pwd:
        raise SystemExit("No SSH credentials available")
    client.connect(
        HOST,
        username=USER,
        password=pwd,
        timeout=30,
        banner_timeout=30,
        allow_agent=False,
        look_for_keys=False,
    )
    return client


def run(client: paramiko.SSHClient, cmd: str, timeout: int = 120) -> tuple[int, str, str]:
    _, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    out = stdout.read().decode()
    err = stderr.read().decode()
    code = stdout.channel.recv_exit_status()
    return code, out, err


def main() -> int:
    client = connect()
    print(f"Connected to {HOST}")

    steps = [
        ("detect", "grep -rl 'syaratiiq.com' /etc/nginx/sites-enabled/ /etc/nginx/sites-available/ 2>/dev/null | sort -u"),
        ("enabled", "ls -la /etc/nginx/sites-enabled/"),
        ("docroot", f"test -d {ROOT} && ls -la {ROOT}/index.php || echo MISSING_ROOT"),
        ("certs", f"test -f /etc/letsencrypt/live/{DOMAIN}/fullchain.pem && echo CERT_OK || echo CERT_MISSING"),
    ]
    for label, cmd in steps:
        code, out, err = run(client, cmd)
        print(f"\n=== {label} ===")
        print(out.strip() or err.strip())

    # Write config to syaratiiq site file
    sftp = client.open_sftp()
    remote_conf = "/etc/nginx/sites-available/syaratiiq"
    with sftp.file(remote_conf, "w") as rf:
        rf.write(NGINX_CONF)
    sftp.close()
    print(f"\nWrote {remote_conf}")

    cmds = [
        "rm -f /etc/nginx/sites-enabled/default",
        "ln -sf /etc/nginx/sites-available/syaratiiq /etc/nginx/sites-enabled/syaratiiq",
        "nginx -t",
        "systemctl reload nginx",
        f"curl -sI https://{DOMAIN}/ | head -20",
        f"curl -sk https://{DOMAIN}/up",
    ]
    for cmd in cmds:
        print(f"\n>>> {cmd}")
        code, out, err = run(client, cmd)
        combined = (out + err).strip()
        print(combined)
        if cmd == "nginx -t" and code != 0:
            print("nginx -t failed", file=sys.stderr)
            return code

    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
