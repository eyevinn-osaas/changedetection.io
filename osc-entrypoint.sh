#!/bin/bash
set -e

# PORT is read natively by changedetection.io; default to the OSC port
export PORT="${PORT:-8080}"

# OSC terminates TLS in front of the app: trust X-Forwarded-* headers
export USE_X_SETTINGS="${USE_X_SETTINGS:-1}"

# OSC_HOSTNAME -> BASE_URL (only used for links in notifications unless the
# "Base URL" setting in the UI is set, which takes precedence)
if [ -n "$OSC_HOSTNAME" ] && [ -z "$BASE_URL" ]; then
  export BASE_URL="https://$OSC_HOSTNAME"
fi

# ADMIN_PASSWORD (plain text, set as a service option) -> SALTED_PASS
# changedetection.io expects base64(salt[32] + pbkdf2_hmac_sha256(password, salt, 100000))
# and has no way to turn plain text into that itself. Without a password the UI is open.
if [ -n "$ADMIN_PASSWORD" ] && [ -z "$SALTED_PASS" ]; then
  SALTED_PASS="$(python3 - <<'PY'
import base64, hashlib, os
pw = os.environ["ADMIN_PASSWORD"].encode("utf-8")
salt = os.urandom(32)
print(base64.b64encode(salt + hashlib.pbkdf2_hmac("sha256", pw, salt, 100000)).decode())
PY
)"
  export SALTED_PASS
fi
unset ADMIN_PASSWORD

mkdir -p /datastore

exec "$@"
