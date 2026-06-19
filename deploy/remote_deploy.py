"""Deploy syaratiiq to VPS via SSH (key or password)."""
from __future__ import annotations

import os
import sys
from pathlib import Path

import paramiko

HOST = os.environ.get("VPS_HOST", "207.180.208.172")
USER = os.environ.get("VPS_USER", "root")
PASSWORD = os.environ.get("VPS_SSH_PASSWORD", "")
KEY_PATH = os.environ.get(
    "VPS_SSH_KEY",
    str(Path(__file__).resolve().parent / "vps_deploy_key"),
)
SCRIPT = Path(__file__).resolve().parent / "vps-direct-deploy.sh"


def load_password() -> str:
    if PASSWORD:
        return PASSWORD
    askpass = Path(__file__).resolve().parent / "askpass.cmd"
    if askpass.is_file():
        for line in askpass.read_text(encoding="utf-8", errors="ignore").splitlines():
            line = line.strip()
            if line.lower().startswith("echo "):
                return line[5:].strip()
    return ""


def connect() -> paramiko.SSHClient:
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())

    if Path(KEY_PATH).is_file():
        try:
            key = paramiko.Ed25519Key.from_private_key_file(KEY_PATH)
            client.connect(
                HOST,
                username=USER,
                pkey=key,
                timeout=60,
                banner_timeout=60,
                allow_agent=False,
                look_for_keys=False,
            )
            return client
        except paramiko.AuthenticationException:
            pass

    pwd = load_password()
    if not pwd:
        raise SystemExit("No SSH key or password available.")

    client.connect(
        HOST,
        username=USER,
        password=pwd,
        timeout=60,
        banner_timeout=60,
        allow_agent=False,
        look_for_keys=False,
    )
    return client


def main() -> int:
    script = SCRIPT.read_text(encoding="utf-8")
    client = connect()
    print(f"Connected to {HOST}")

    sftp = client.open_sftp()
    remote = "/root/vps-direct-deploy.sh"
    with sftp.file(remote, "w") as rf:
        rf.write(script)
    sftp.chmod(remote, 0o750)
    sftp.close()

    print("Running deployment...")
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
