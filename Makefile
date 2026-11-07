# Makefile … よく使う作業を、リポジトリの直下から make ○○ で実行する
#
#   make          … 使えるものの一覧（make help と同じ）
#   make up       … 全部をビルドして起動（http://localhost:8000）
#   make smoke    … 全体の疎通の確認（結果は smoke-result/）
#   make test     … すべてのテスト（CI と同じもの）
#
# Docker（Docker Desktop）と Flutter があれば動く。Node・Elixir・Python は、なければ Docker の中で動かす
# 個人の情報は使わない（データはサンプルの利用者 sample@example.com だけ）

SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help up start down stop ps logs seed smoke open dev run profile \
        test test-frontend test-api test-api-emulator test-auth test-auth-emulator test-excel test-seed \
        analyze imports measure

ROOT := $(CURDIR)
# 手元に npm があればそれを、なければ Docker の Node 22 を使う
HAVE_NPM := $(shell command -v npm 2>/dev/null)
NODE_IN_DOCKER = docker run --rm -v "$(ROOT)":/repo -w /repo/$(1) node:22-alpine sh -c
ELIXIR_IN_DOCKER = docker run --rm -v "$(ROOT)/services/auth-phoenix":/app -w /app -e MIX_ENV=test
MIX_PREPARE = mix local.hex --force && mix local.rebar --force && mix deps.get

help: ## 使えるものの一覧
	@echo "使い方：make ○○（リポジトリの直下で）"
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "引数：make logs S=api（1 つのサービスだけ）・make test-frontend F=test/account_test.dart（1 ファイルだけ）・make profile P=my.yaml"

# ---------------- 起動（docker compose） ----------------

up: ## 全部をビルドして起動（画面 http://localhost:8000・Emulator の画面 http://localhost:4001）
	docker compose up -d --build
	@echo "画面：http://localhost:8000（make seed でサンプルの利用者 sample@example.com / sample-password）"

start: ## ビルドしないで起動
	docker compose up -d

stop: ## 止める（Emulator のデータは firebase/emulator-data に書き出す）
	docker compose stop

down: ## 止めてコンテナを消す（Emulator のデータは残る）
	docker compose down

ps: ## 動いているものと状態
	docker compose ps

logs: ## ログを見る（S=api などで 1 つだけ。Ctrl+C で終わる）
	docker compose logs -f --tail 100 $(S)

seed: ## Emulator にサンプル（架空のデータ）を入れる。何度でもよい
	docker compose run --rm seed

smoke: ## 全体の疎通の確認（起動し直し・ログイン・API・見る人向けのスキルシート・FastAPI のテスト）
	bash scripts/smoke.sh

open: ## 画面をブラウザで開く
	open http://localhost:8000

# ---------------- Flutter で直接 ----------------

dev: ## Flutter で画面を開く（ログインあり。make up のあとに。http://localhost:5000）
	cd frontend && flutter run -d chrome --web-port 5000 \
	  --dart-define=ENABLE_ACCOUNT=true \
	  --dart-define=API_BASE=http://localhost:8787 \
	  --dart-define=AUTH_BASE=http://localhost:4100

run: ## Flutter で公開ページだけを開く（ログインなし。本番と同じ）
	cd frontend && flutter run -d chrome

profile: ## 自分のプロフィールを指定して開く（P=my_profile.yaml。ファイルは Git に入れない）
	@test -n "$(P)" || { echo "P=プロフィールのファイル を付けてください（例：make profile P=skill_sheet_yaml/my.yaml）"; exit 2; }
	cd frontend && dart run tool/run.dart "$(abspath $(P))"

# ---------------- テスト ----------------

test: test-frontend test-api test-auth test-excel test-seed ## すべてのテスト（CI と同じ）
	@echo "すべてのテストが通りました"

test-frontend: ## Flutter：静的解析・テスト・網羅率（F=ファイルで 1 つだけ。そのときは網羅率を見ない）
	cd frontend && flutter pub get
	cd frontend && flutter analyze
ifeq ($(F),)
	cd frontend && flutter test --coverage --branch-coverage
	cd frontend && dart run tool/coverage_check.dart
else
	cd frontend && flutter test $(patsubst frontend/%,%,$(F))
endif

analyze: ## Flutter の静的解析だけ
	cd frontend && flutter analyze

imports: ## lib/ にファイルを足したら（網羅率の集計に入れる test/all_files_loaded_test.dart を作り直す）
	cd frontend && dart run tool/coverage_check.dart --update-imports

measure: ## スキルシート（Excel・PDF）を作る時間を測る（docs/plan/excel.md）
	cd frontend && dart run tool/measure_skill_sheet.dart

test-api: ## API（Hono）：型の確認とテスト
ifneq ($(HAVE_NPM),)
	cd services/api-hono && npm ci && npm run typecheck && npm test
else
	$(call NODE_IN_DOCKER,services/api-hono) "npm ci && npm run typecheck && npm test"
endif

test-api-emulator: ## API（Hono）：Emulator の上のテスト（make up のあとに）
ifneq ($(HAVE_NPM),)
	cd services/api-hono && FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run test:emulator
else
	docker run --rm --network dev-portfolio_default -v "$(ROOT)":/repo -w /repo/services/api-hono \
	  -e FIRESTORE_EMULATOR_HOST=firebase:8080 -e FIREBASE_AUTH_EMULATOR_HOST=firebase:9099 \
	  node:22-alpine sh -c "npm ci && npm run test:emulator"
endif

test-auth: ## 認証（Phoenix）：警告もエラーにするコンパイルとテスト（Docker の中で）
	$(ELIXIR_IN_DOCKER) elixir:1.18-alpine sh -c "$(MIX_PREPARE) && mix compile --warnings-as-errors && mix test"

test-auth-emulator: ## 認証（Phoenix）：Emulator の上のテスト（make up のあとに）
	$(ELIXIR_IN_DOCKER) --network dev-portfolio_default -e FIREBASE_AUTH_EMULATOR_HOST=firebase:9099 \
	  elixir:1.18-alpine sh -c "$(MIX_PREPARE) && mix test --only emulator"

test-excel: ## 見る人向けのスキルシート（FastAPI）：テストと網羅率（Docker の中で）
	docker run --rm -v "$(ROOT)":/repo -w /repo/services/excel-fastapi python:3.12-slim sh -c \
	  "pip install -q --root-user-action=ignore -r requirements-dev.txt && pytest -p no:cacheprovider --cov=app --cov-branch --cov-report=term-missing --cov-fail-under=90"
	@rm -f services/excel-fastapi/.coverage; find services/excel-fastapi -name __pycache__ -type d -prune -exec rm -rf {} +

test-seed: ## Emulator にサンプルを入れるスクリプトのテスト
ifneq ($(HAVE_NPM),)
	node --test firebase/seed/seed.test.mjs
else
	$(call NODE_IN_DOCKER,.) "node --test firebase/seed/seed.test.mjs"
endif
