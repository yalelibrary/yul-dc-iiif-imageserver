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
require_env IIIF_IMAGE_KEYSTORE

extract_json_secret_value() {
  local secret_value="$1"
  local json_key="$2"

  if [[ "$secret_value" =~ ^[[:space:]]*\{ ]]; then
    printf '%s' "$secret_value" | ruby -rjson -e '
      key = ENV["JSON_KEY"]
      data = JSON.parse(STDIN.read)
      unless data.is_a?(Hash)
        warn("JSON secret must be an object")
        exit(1)
      end

      value = data[key] || data[key.downcase]
      print(value.to_s)
    ' JSON_KEY="$json_key"
  fi
}

if [[ -z "${HTTPS_KEY_STORE_PASSWORD:-}" ]]; then
  HTTPS_KEY_STORE_PASSWORD="$(extract_json_secret_value "${IIIF_IMAGE_KEYSTORE}" "HTTPS_KEY_STORE_PASSWORD")"
fi

require_env HTTPS_KEY_STORE_PASSWORD
require_env HTTPS_KEY_PASSWORD
require_env HTTPS_KEY_STORE_PATH

extract_keystore_b64() {
  local secret_value="$1"
  local json_key

  # Support either a plain base64 string or a JSON object containing it.
  if [[ "$secret_value" =~ ^[[:space:]]*\{ ]]; then
    json_key="${IIIF_IMAGE_KEYSTORE_JSON_KEY:-IIIF_IMAGE_KEYSTORE}"
    printf '%s' "$secret_value" | ruby -rjson -e '
      key = ENV["IIIF_IMAGE_KEYSTORE_JSON_KEY"] || "IIIF_IMAGE_KEYSTORE"
      data = JSON.parse(STDIN.read)
      unless data.is_a?(Hash)
        warn("IIIF_IMAGE_KEYSTORE JSON secret must be an object")
        exit(1)
      end

      value = data[key] || data[key.downcase] || data["keystore_b64"] || data["keystore"]
      if value.nil? || value.to_s.empty?
        warn("IIIF_IMAGE_KEYSTORE JSON secret does not contain key: #{key}")
        exit(1)
      end

      print(value)
    ' IIIF_IMAGE_KEYSTORE_JSON_KEY="$json_key"
  else
    printf '%s' "$secret_value"
  fi
}

HTTPS_KEY_STORE_TYPE="${HTTPS_KEY_STORE_TYPE:-PKCS12}"
HTTPS_KEY_STORE_PATH="${HTTPS_KEY_STORE_PATH:-/cantaloupe/certs/cantaloupe.p12}"

mkdir -p "$(dirname "${HTTPS_KEY_STORE_PATH}")"

# Decode keystore from secret into file with restrictive permissions.
umask 077
KEYSTORE_B64="$(extract_keystore_b64 "${IIIF_IMAGE_KEYSTORE}")"
printf '%s' "${KEYSTORE_B64}" | tr -d '\r\n' | base64 -d > "${HTTPS_KEY_STORE_PATH}"

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