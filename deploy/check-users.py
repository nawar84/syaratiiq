"""Check production users and seed if missing."""
from __future__ import annotations

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
    _, stdout, stderr = client.exec_command(cmd, timeout=120)
    out = stdout.read().decode("utf-8", errors="replace")
    err = stderr.read().decode("utf-8", errors="replace")
    return stdout.channel.recv_exit_status(), out, err


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: check-users.py <ssh-password>", file=sys.stderr)
        return 2

    client = connect(sys.argv[1])
    cmds = [
        f"cd {BACKEND} && php artisan tinker --execute=\"echo User::query()->select('id','username','phone','role')->get()->toJson(JSON_UNESCAPED_UNICODE);\" 2>/dev/null || cd {BACKEND} && php -r \"require 'vendor/autoload.php'; \\$app=require 'bootstrap/app.php'; \\$app->make('Illuminate\\\\Contracts\\\\Console\\\\Kernel')->bootstrap(); echo App\\\\Models\\\\User::query()->select('id','username','phone','role')->get()->toJson(JSON_UNESCAPED_UNICODE);\"",
    ]
    for cmd in cmds:
        print(f">>> {cmd[:120]}...")
        code, out, err = run(client, cmd)
        print(out.strip())
        if err.strip():
            print(err.strip())
        if code == 0 and out.strip():
            break

    client.close()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
