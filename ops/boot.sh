#!/bin/bash
set -euo pipefail

require_env() {
  var_name="$1"
  if [ -z "${!var_name:-}" ]; then
    echo "Missing required environment variable: ${var_name}" >&2
    exit 1
  fi
}

# Expect these to come from ECS task secrets/environment.
# IIIF_IMAGE_KEYSTORE should be base64-encoded PKCS12 content.
require_env IIIF_IMAGE_KEYSTORE
require_env HTTPS_KEY_STORE_PASSWORD
require_env HTTPS_KEY_PASSWORD

HTTPS_KEY_STORE_TYPE="${HTTPS_KEY_STORE_TYPE:-PKCS12}"
HTTPS_KEY_STORE_PATH="${HTTPS_KEY_STORE_PATH:-/cantaloupe/certs/cantaloupe.p12}"

mkdir -p "$(dirname "${HTTPS_KEY_STORE_PATH}")"

# Decode keystore from secret into file with restrictive permissions.
umask 077
printf '%s' "${IIIF_IMAGE_KEYSTORE}" | tr -d '\r\n' | base64 -d > "${HTTPS_KEY_STORE_PATH}"

# Ensure the runtime user can read it.
chown cantaloupe:cantaloupe "${HTTPS_KEY_STORE_PATH}" 2>/dev/null || chown cantaloupe "${HTTPS_KEY_STORE_PATH}"
chmod 400 "${HTTPS_KEY_STORE_PATH}"

# Fail-fast validation of keystore/password correctness.
keytool -list \
  -storetype "${HTTPS_KEY_STORE_TYPE}" \
  -keystore "${HTTPS_KEY_STORE_PATH}" \
  -storepass "${HTTPS_KEY_STORE_PASSWORD}" >/dev/null

# Start Cantaloupe
exec su cantaloupe -s /bin/sh /bin/sh -c "GEM_PATH=/jruby/lib/ruby/gems/shared java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties ${IIIF_JAVA_OPTS:-} -jar /cantaloupe/cantaloupe-${CANTALOUPE_VERSION}.jar"