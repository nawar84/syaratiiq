"""Execute syaratiiq production deployment on VPS."""
import os
import sys

import paramiko

HOST = os.environ.get("VPS_HOST", "207.180.208.172")
USER = os.environ.get("VPS_USER", "root")
PASSWORD = os.environ.get("VPS_SSH_PASSWORD", "")
SCRIPT = os.path.join(os.path.dirname(__file__), "vps-syaratiiq-production.sh")


def main() -> int:
    if not PASSWORD:
        print("Set VPS_SSH_PASSWORD", file=sys.stderr)
        return 1

    with open(SCRIPT, encoding="utf-8") as f:
        script = f.read()

    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    print(f"Connecting to {HOST}...")
    client.connect(HOST, username=USER, password=PASSWORD, timeout=60, banner_timeout=60)

    sftp = client.open_sftp()
    remote = "/root/vps-syaratiiq-production.sh"
    with sftp.file(remote, "w") as rf:
        rf.write(script)
    sftp.chmod(remote, 0o750)
    sftp.close()

    print("Running production deployment...")
    _, stdout, stderr = client.exec_command(f"bash {remote}", get_pty=True, timeout=3600)
    for line in iter(stdout.readline, ""):
        print(line, end="")

    code = stdout.channel.recv_exit_status()
    err = stderr.read().decode()
    if err.strip():
        print(err, file=sys.stderr)
    client.close()
    return code


if __name__ == "__main__":
    raise SystemExit(main())
