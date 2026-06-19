"""Upload and run VPS setup script via SSH. Usage: set VPS_SSH_PASSWORD env var."""
import os
import secrets
import string
import sys

import paramiko

HOST = os.environ.get("VPS_HOST", "207.180.208.172")
USER = os.environ.get("VPS_USER", "root")
PASSWORD = os.environ.get("VPS_SSH_PASSWORD", "")
SCRIPT_PATH = os.path.join(os.path.dirname(__file__), "vps-remote-setup.sh")


def main() -> int:
    if not PASSWORD:
        print("Set VPS_SSH_PASSWORD environment variable.", file=sys.stderr)
        return 1

    db_pass = "".join(secrets.choice(string.ascii_letters + string.digits) for _ in range(24))

    with open(SCRIPT_PATH, encoding="utf-8") as f:
        script = f.read()

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Connecting to {HOST}...")
    client.connect(HOST, username=USER, password=PASSWORD, timeout=30)

    sftp = client.open_sftp()
    remote_path = "/root/vps-remote-setup.sh"
    with sftp.file(remote_path, "w") as remote:
        remote.write(script)
    sftp.chmod(remote_path, 0o750)
    sftp.close()

    cmd = f"export DB_PASS='{db_pass}' APP_IP='{HOST}'; bash {remote_path}"
    print("Running remote setup (may take 15-30 minutes)...")
    stdin, stdout, stderr = client.exec_command(cmd, get_pty=True, timeout=3600)

    for line in iter(stdout.readline, ""):
        print(line, end="")

    exit_code = stdout.channel.recv_exit_status()
    err = stderr.read().decode()
    if err:
        print(err, file=sys.stderr)

    creds_path = os.path.join(os.path.dirname(__file__), "VPS_CREDENTIALS.local.txt")
    with open(creds_path, "w", encoding="utf-8") as f:
        f.write(f"VPS IP: {HOST}\n")
        f.write(f"API URL: http://{HOST}/api\n")
        f.write(f"DB_NAME: car_iq\n")
        f.write(f"DB_USER: car_iq\n")
        f.write(f"DB_PASSWORD: {db_pass}\n")
        f.write("Admin login: admin / 1234\n")
        f.write("Seller login: 1234 / 1234\n")

    print(f"\nCredentials saved to: {creds_path}")
    print(f"Exit code: {exit_code}")
    client.close()
    return exit_code


if __name__ == "__main__":
    raise SystemExit(main())
