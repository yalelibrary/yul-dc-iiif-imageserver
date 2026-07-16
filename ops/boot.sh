#!/bin/bash
set -euo pipefail

require_env() {
  var_name="$1"
  if [ -z "${!var_name:-}" ]; then
    echo "Missing required environment variable: ${var_name}" >&2
    exit 1
  fi
}

HTTPS_KEY_STORE_TYPE="${HTTPS_KEY_STORE_TYPE:-PKCS12}"
HTTPS_KEY_STORE_PATH="${HTTPS_KEY_STORE_PATH:-/cantaloupe/certs/cantaloupe.p12}"

# HTTPS keystore resolution, in priority order:
#   1. IIIF_IMAGE_KEYSTORE (base64 secret, deployed)      -> decode into the keystore path
#   2. a keystore file already mounted at the path (dev)  -> use it in place, read-only
#   3. neither                                            -> HTTP-only (no HTTPS connector)
if [ -n "${IIIF_IMAGE_KEYSTORE:-}" ]; then
  require_env HTTPS_KEY_STORE_PASSWORD
  require_env HTTPS_KEY_PASSWORD

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
    -storepass "${HTTPS_KEY_STORE_PASSWORD}" 2>&1
elif [ -f "${HTTPS_KEY_STORE_PATH}" ] && [ -s "${HTTPS_KEY_STORE_PATH}" ]; then
  # A keystore file is already present at the path (mounted in local dev). Use it in
  # place and do NOT write to it, so the read-only mount is fine and HTTPS still works.
  require_env HTTPS_KEY_STORE_PASSWORD
  require_env HTTPS_KEY_PASSWORD

  keytool -list \
    -storetype "${HTTPS_KEY_STORE_TYPE}" \
    -keystore "${HTTPS_KEY_STORE_PATH}" \
    -storepass "${HTTPS_KEY_STORE_PASSWORD}" 2>&1
else
  echo "No keystore (IIIF_IMAGE_KEYSTORE unset and no file at ${HTTPS_KEY_STORE_PATH}); starting Cantaloupe HTTP-only." >&2
  # Override https.enabled=true from cantaloupe.properties so Cantaloupe does not try
  # to bind the HTTPS connector (8183) without a keystore.
  export HTTPS_ENABLED=false
fi

# Start Cantaloupe
echo "launching Cantaloupe" >&2
exec su cantaloupe -s /bin/sh /bin/sh -c "GEM_PATH=/jruby/lib/ruby/gems/shared java -Dcantaloupe.config=/cantaloupe/cantaloupe.properties ${IIIF_JAVA_OPTS:-} -jar /cantaloupe/cantaloupe-${CANTALOUPE_VERSION}.jar"