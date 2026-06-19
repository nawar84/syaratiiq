"""Seed production database with default demo users."""
from __future__ import annotations

import json
import sys

import paramiko

HOST = "207.180.208.172"
USER = "root"
BACKEND = "/var/www/syaratiiq/backend"


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


def run(client: paramiko.SSHClient, cmd: str) -> tuple[int, str, str]:
    _, stdout, stderr = client.exec_command(cmd, timeout=300)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    return stdout.channel.recv_exit_status(), out, err


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: seed-production.py <ssh-password>", file=sys.stderr)
        return 2

    client = connect(sys.argv[1])

    seed_cmd = f"cd {BACKEND} && php artisan db:seed --force"
    print(f">>> {seed_cmd}")
    code, out, err = run(client, seed_cmd)
    print(out.strip())
    if err.strip():
        print(err.strip())
    if code != 0:
        client.close()
        return code

    list_cmd = (
        f"cd {BACKEND} && php artisan tinker --execute="
        "\"print(App\\\\Models\\\\User::query()->select('username','phone','role')->get()->toJson(JSON_UNESCAPED_UNICODE));\""
    )
    print(f"\n>>> list users")
    code, out, err = run(client, list_cmd)
    print(out.strip())
    if err.strip():
        print(err.strip())

    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
