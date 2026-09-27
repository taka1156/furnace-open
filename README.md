<p align="center">
  <img src="./furnace.png" alt="furnace logo" width="200">
</p>

# furnace

## 概要
Cloudflare 上で運用する Web サービスのインフラストラクチャを、Terraform で管理するプロジェクトです。Cloudflare Provider を使ってリソースを宣言的に管理し、既存リソースのTerraform設定を生成する補助スクリプトも用意しています。

## 機能
- Cloudflare Pagesプロジェクト、D1データベース、R2バケット、Workers KVネームスペースの設定生成
- Workersスクリプトのimportブロックおよび設定生成
- Cloudflare ZoneのDNSレコードの設定生成
- Terraformの初期化、フォーマット、検証、Plan、リソースのダンプをMakefileから実行

## 前提条件
- GNU Make
- Terraform CLI
- Cloudflare APIトークンとAccount ID、Zone ID
- `make dump`を使う場合: `cf-terraforming`、`curl`、`jq`
- `make lint`を使う場合: `secretlint`

Cloudflare APIトークンには、対象リソースの読み取りに必要な権限を付与してください。Terraform Providerや`cf-terraforming`のバージョンは、使用環境に合わせて管理してください。

## セットアップ
1. リポジトリのルートで環境変数ファイルを作成します。

  ```sh
  cp .env.example .env
  ```

2. `.env`のプレースホルダーを実際の値に置き換えます。Terraform用の`TF_VAR_`変数と、ダンプスクリプト用の変数の両方を設定してください。

  ```dotenv
  TF_VAR_cloudflare_api_token=<Cloudflare API token>
  TF_VAR_cloudflare_account_id=<Cloudflare Account ID>
  TF_VAR_cloudflare_zone_id=<Cloudflare Zone ID>

  CLOUDFLARE_API_TOKEN=<Cloudflare API token>
  CLOUDFLARE_ACCOUNT_ID=<Cloudflare Account ID>
  CLOUDFLARE_ZONE_ID=<Cloudflare Zone ID>
  ```

  `.env`はGit管理対象外です。APIトークンなどの秘密情報をコミットしないでください。

3. Terraformを初期化し、設定を検証します。

  ```sh
  make init
  make validate
  ```

## Makeコマンド
| コマンド | 説明 |
| --- | --- |
| `make help` | ターゲット一覧を表示 |
| `make init` | `infra/`でTerraformを初期化（backendなし） |
| `make fmt` | `infra/`以下のTerraform設定を再帰的にフォーマット |
| `make validate` | 初期化後、Terraform設定を検証 |
| `make plan` | `.env`を読み込み、`infra/`の変更差分を表示 |
| `make dump` | Cloudflareの既存リソースからTerraform設定を生成 |
| `make lint` | Secretlintで秘密情報の混入を検査 |
| `make clean OUTPUT_DIR=<path>` | 指定した出力先を削除 |

`make apply`はMakefileにターゲット名がありますが、適用処理はコメントアウトされており、現時点では利用できません。変更を適用する前に`make plan`の結果を確認してください。

## 既存リソースのダンプ
`make dump`は`.env`の認証情報を使い、Pages、D1、R2、Workers KV、DNSレコードの設定を生成します。Workersスクリプトはcf-terraformingではダンプできないため、`dump-workers.sh`でCloudflare APIからスクリプト名を取得し、Terraformのimportブロックを作成してから`terraform plan -generate-config-out`で設定を生成します。この専用処理が必要なため、Workersだけ別の手順になっています。生成内容を確認し、必要に応じて調整したうえで管理対象に加えてください。

```sh
make dump
```

既定の出力先は`infra/`です。既存のTerraform設定と同じ場所に生成されるため、実行前に状態を確認してください。別の出力先を指定する場合は、`OUTPUT_DIR`を上書きできます。

```sh
make dump OUTPUT_DIR=generated
```

Workersスクリプトの設定生成では、指定した出力先をTerraformの作業ディレクトリとして`plan`を実行します。そのため、別の出力先を使う場合は、実行前にCloudflare Provider設定と変数定義を用意してTerraformを初期化してください。

`make clean`の既定出力先も`infra/`であり、そのディレクトリを削除します。実行する場合は、必ず削除対象を指定してください。

```sh
make clean OUTPUT_DIR=generated
```

## ディレクトリ構成
```text
.
├── dump.sh             # Pages、D1、R2、KV、DNSの設定生成
├── dump-workers.sh     # Workersスクリプトのimportと設定生成
├── infra/              # Terraform Provider、変数、リソース設定
├── Makefile            # Terraform操作と補助コマンド
└── .env.example        # 環境変数のひな形
```
