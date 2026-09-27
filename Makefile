SHELL := /usr/bin/env bash

# --- Config (環境変数や引数で上書き可能) ---
ENV_FILE     ?= .env
INFRA_DIR    ?= infra
OUTPUT_DIR   ?= infra

.DEFAULT_GOAL := help

.PHONY: help init fmt validate plan apply dump clean lint check-env

## help: 使えるコマンド一覧を表示
help:
	@echo "使い方: make <target>"
	@echo ""
	@echo "  make init         infra ディレクトリで terraform init (backendなし)"
	@echo "  make fmt          terraform fmt をかける"
	@echo "  make validate     terraform validate で構文チェック"
	@echo "  make plan         terraform plan を実行"
	@echo "  make apply        terraform apply を実行"
	@echo "  make dump         dump.sh, dump-workers.sh を実行して既存リソースをHCL化"
	@echo "  make clean        生成物(OUTPUT_DIR)を削除"

## check-env: .env の存在を確認する内部ターゲット
check-env:
	@if [[ ! -f "$(ENV_FILE)" ]]; then \
		echo "Error: $(ENV_FILE) not found" >&2; \
		exit 1; \
	fi

## init: infra ディレクトリでprovider初期化のみ行う(backend接続はしない)
init:
	cd $(INFRA_DIR) && terraform init -backend=false

## fmt: HCLフォーマット
fmt:
	cd $(INFRA_DIR) && terraform fmt -recursive

## validate: 構文チェック
validate: init
	cd $(INFRA_DIR) && terraform validate

## plan: 差分確認
plan: check-env init
	set -a; source $(ENV_FILE); set +a; \
	cd $(INFRA_DIR) && terraform plan

## apply: 適用(要確認プロンプトあり)
# apply: check-env init
# 	set -a; source $(ENV_FILE); set +a; \
# 	cd $(INFRA_DIR) && terraform apply

## dump: 既存Cloudflareリソースをdump.shでHCL化
dump: check-env
	set -a; source $(ENV_FILE); set +a; \
	INFRA_DIR=$(INFRA_DIR) ./dump.sh $(OUTPUT_DIR)
	INFRA_DIR=$(INFRA_DIR) ./dump-workers.sh $(OUTPUT_DIR)

## clean: 生成物を削除
clean:
	rm -rf $(OUTPUT_DIR)

## secretを検出
lint:
	secretlint "**/*"
