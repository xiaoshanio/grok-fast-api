#!/usr/bin/env sh
set -eu

/app/scripts/init_storage.sh
. /app/scripts/init_aiven_ca.sh

exec "$@"
