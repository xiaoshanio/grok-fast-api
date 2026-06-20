#!/usr/bin/env sh
set -eu

DATA_DIR="${DATA_DIR:-/app/data}"
AIVEN_CA_CERT_PATH="${AIVEN_CA_CERT_PATH:-$DATA_DIR/aiven-ca.pem}"

if [ -n "${AIVEN_CA_CERT:-}" ]; then
  mkdir -p "$(dirname "$AIVEN_CA_CERT_PATH")"
  printf '%s\n' "$AIVEN_CA_CERT" > "$AIVEN_CA_CERT_PATH"
  chmod 600 "$AIVEN_CA_CERT_PATH" || true
fi

if [ ! -f "$AIVEN_CA_CERT_PATH" ]; then
  return 0 2>/dev/null || exit 0
fi

if [ -n "${ACCOUNT_POSTGRESQL_URL:-}" ]; then
  case "$ACCOUNT_POSTGRESQL_URL" in
    *sslrootcert=*) ;;
    *\?*) ACCOUNT_POSTGRESQL_URL="${ACCOUNT_POSTGRESQL_URL}&sslrootcert=${AIVEN_CA_CERT_PATH}" ;;
    *) ACCOUNT_POSTGRESQL_URL="${ACCOUNT_POSTGRESQL_URL}?sslrootcert=${AIVEN_CA_CERT_PATH}" ;;
  esac
  export ACCOUNT_POSTGRESQL_URL
fi
