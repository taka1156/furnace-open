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
 
echo "==> Dump Cloudflare resources"
echo "    Output: $OUTPUT_DIR"
echo
 
dump_account() {
  local resource_type="$1"
  local output_file="$2"

  echo "Dumping ${resource_type} -> ${output_file}"

  (
    unset CLOUDFLARE_ZONE_ID
    cf-terraforming generate \
      --resource-type "$resource_type" \
      --account "$CLOUDFLARE_ACCOUNT_ID" \
      --terraform-install-path "$INFRA_DIR" \
      --terraform-binary-path "$(which terraform)" \
      > "$OUTPUT_DIR/$output_file"
  )
}

dump_zone() {
  local resource_type="$1"
  local output_file="$2"

  echo "Dumping ${resource_type} -> ${output_file}"

  (
    unset CLOUDFLARE_ACCOUNT_ID
    cf-terraforming generate \
      --resource-type "$resource_type" \
      --zone "$CLOUDFLARE_ZONE_ID" \
      --terraform-install-path "$INFRA_DIR" \
      --terraform-binary-path "$(which terraform)" \
      > "$OUTPUT_DIR/$output_file"
  )
}

sanitize_ids() {
  local file="$1"
  [[ -f "$file" ]] || return 0

  # ダブルクォートで囲まれたID値を変数参照に置換
  sed -i \
    -e "s/\"${CLOUDFLARE_ACCOUNT_ID}\"/var.cloudflare_account_id/g" \
    -e "s/\"${CLOUDFLARE_ZONE_ID}\"/var.cloudflare_zone_id/g" \
    "$file"
}
 
# Workers
# 専用の処理で生成
# dump_account \
#   cloudflare_workers_script \
#   workers.tf
 
# Pages
dump_account \
  cloudflare_pages_project \
  pages.tf
 
# D1
dump_account \
  cloudflare_d1_database \
  d1.tf
 
# R2
dump_account \
  cloudflare_r2_bucket \
  r2.tf
 
# KV
dump_account \
  cloudflare_workers_kv_namespace \
  kv.tf
 
# --- DNS ---
 
# DNSレコード
dump_zone \
  cloudflare_dns_record \
  dns.tf
 
# ゾーン全体の設定（SSL/TLS, セキュリティレベル等、DNS関連の挙動も含む）
# dump_zone \
#   cloudflare_zone_settings_override \
#   zone_settings.tf
 
# DNSSEC設定
# dump_zone \
#   cloudflare_zone_dnssec \
#   dnssec.tf
 
# --- ロギング ---
 
# Logpushジョブ（アカウントレベル）
# Enterprise
# dump_account \
#   cloudflare_logpush_job \
#   logpush.tf


sanitize_ids "$OUTPUT_DIR/pages.tf"
# 廃止済みのフィールド削除
sed -i '/usage_model/d' "$OUTPUT_DIR/pages.tf"
sanitize_ids "$OUTPUT_DIR/d1.tf"
sanitize_ids "$OUTPUT_DIR/r2.tf"
sanitize_ids "$OUTPUT_DIR/kv.tf"
sanitize_ids "$OUTPUT_DIR/dns.tf"

echo
echo "==> Done"
echo
