#!/usr/bin/env bash

set -euo pipefail

ENV_FILE=".env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Error: .env not found: $ENV_FILE" >&2
  exit 1
fi

# .env を読み込んで export する
set -a

# shellcheck source=/dev/null
source "$ENV_FILE"
set +a

: "${CLOUDFLARE_ACCOUNT_ID:?CLOUDFLARE_ACCOUNT_ID is required (check .env)}"
: "${CLOUDFLARE_ZONE_ID:?CLOUDFLARE_ZONE_ID is required (check .env)}"
: "${CLOUDFLARE_API_TOKEN:?CLOUDFLARE_API_TOKEN is required (check .env)}"

OUTPUT_DIR="${1:-./generated}"
 
mkdir -p "$OUTPUT_DIR"
 
echo "==> Dump Cloudflare Workers resources"
echo "    Output: $OUTPUT_DIR"
echo

sanitize_ids() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  # ダブルクォートで囲まれたID値を変数参照に置換
  sed -i \
    -e "s/\"${CLOUDFLARE_ACCOUNT_ID}\"/var.cloudflare_account_id/g" \
    -e "s/\"${CLOUDFLARE_ZONE_ID}\"/var.cloudflare_zone_id/g" \
    "$file"
}

urlencode_segment() {
  jq -rn --arg value "$1" '$value | @uri'
}

encoded_account_id=$(urlencode_segment "$CLOUDFLARE_ACCOUNT_ID")

> "$OUTPUT_DIR/import_workers.tf"

# https://developers.cloudflare.com/api/resources/workers/subresources/scripts/methods/list/
curl -s -X GET "https://api.cloudflare.com/client/v4/accounts/${CLOUDFLARE_ACCOUNT_ID}/workers/scripts" \
     -H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
     -H "Content-Type: application/json" | \
jq -r '.result[] | .id' | while read -r worker_id; do

tf_name=$(echo "$worker_id" | tr '-' '_')
encoded_worker_id=$(urlencode_segment "$worker_id")

cat <<EOF >> "$OUTPUT_DIR/import_workers.tf"
import {
  to = cloudflare_workers_script.$tf_name
  id = join(var.cloudflare_account_id, "/$encoded_worker_id")
}
EOF
done

sanitize_ids "$OUTPUT_DIR/import_workers.tf"

terraform -chdir="$OUTPUT_DIR" plan -generate-config-out=workers.tf

sanitize_ids "$OUTPUT_DIR/workers.tf"

echo
echo "==> Done"
echo
