import os
from pathlib import Path


def _init_aiven_ca() -> None:
    ca_cert = os.getenv("AIVEN_CA_CERT")
    ca_path = Path(os.getenv("AIVEN_CA_CERT_PATH", "/tmp/grok2api-data/aiven-ca.pem"))

    if ca_cert:
        ca_path.parent.mkdir(parents=True, exist_ok=True)
        ca_path.write_text(ca_cert.rstrip() + "\n", encoding="utf-8")

    if not ca_path.is_file():
        return

    dsn = os.getenv("ACCOUNT_POSTGRESQL_URL", "")
    if dsn and "sslrootcert=" not in dsn:
        separator = "&" if "?" in dsn else "?"
        os.environ["ACCOUNT_POSTGRESQL_URL"] = f"{dsn}{separator}sslrootcert={ca_path}"


_init_aiven_ca()

from app.main import app
