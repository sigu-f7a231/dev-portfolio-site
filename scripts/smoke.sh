#!/usr/bin/env bash
# scripts/smoke.sh … ローカルの全体（docker compose）の疎通を確かめる（リポジトリの直下で）
#
#   bash scripts/smoke.sh            … 起動し直し → サンプルを入れる → 各サービス・ログイン・API・見る人向けの PDF・FastAPI のテスト
#   bash scripts/smoke.sh --no-build … ビルドしないで確かめる
#
# 結果は smoke-result/（Git 管理外）に書く：result.txt（PASS / FAIL の一覧）・log.txt（細かい出力）・skill-sheet.pdf
# 使うのはサンプルの利用者（sample@example.com。架空のデータ）だけ。個人の情報は使わない
# 失敗しても止まらず、最後まで確かめる。終わりの数字は FAIL の数
set -u
cd "$(dirname "$0")/.."

OUT=smoke-result
mkdir -p "$OUT"
RESULT="$OUT/result.txt"
LOG="$OUT/log.txt"
: >"$RESULT"
: >"$LOG"
FAILS=0
BASE=http://localhost:8000

log() { printf '%s\n' "$*" >>"$LOG"; }
pass() { printf 'PASS  %s\n' "$1" | tee -a "$RESULT"; }
fail() { printf 'FAIL  %s（%s）\n' "$1" "$2" | tee -a "$RESULT"; FAILS=$((FAILS + 1)); }
# check 名前 期待 実際
check() { if [ "$3" = "$2" ]; then pass "$1"; else fail "$1" "期待 $2・実際 $3"; fi; }
contains() { if printf '%s' "$3" | grep -q -- "$2"; then pass "$1"; else fail "$1" "「$2」がない"; fi; }
code() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

echo "== $(date '+%Y-%m-%d %H:%M:%S') 疎通の確認 ==" | tee -a "$RESULT"

# ---------- 起動 ----------
if [ "${1:-}" != "--no-build" ]; then
  echo "起動し直しています（数分かかることがあります）…"
  docker compose up -d --build >>"$LOG" 2>&1 || fail "docker compose up --build" "log.txt を見る"
else
  docker compose up -d >>"$LOG" 2>&1 || fail "docker compose up" "log.txt を見る"
fi

# healthy になるまで待つ（最大 3 分）
for i in $(seq 1 90); do
  ps=$(docker compose ps --format '{{.Service}} {{.Health}}' 2>/dev/null)
  if ! printf '%s\n' "$ps" | grep -E '^(api|auth|firebase|excel) ' | grep -vq ' healthy$'; then break; fi
  sleep 2
done
log "--- docker compose ps"; docker compose ps >>"$LOG" 2>&1
for s in api auth firebase excel; do
  h=$(docker compose ps --format '{{.Service}} {{.Health}}' 2>/dev/null | awk -v s="$s" '$1==s{print $2}')
  check "コンテナ $s が healthy" healthy "${h:-なし}"
done
# frontend（nginx）は api・auth が healthy になってから起動する。画面が答えるまで待つ（最大 1 分）
for i in $(seq 1 30); do
  [ "$(code http://localhost:8000/)" = 200 ] && break
  sleep 2
done
# frontend（nginx）はヘルスチェックを持たないので、動いているかだけ
st=$(docker compose ps --format '{{.Service}} {{.State}}' 2>/dev/null | awk '$1=="frontend"{print $2}')
check "コンテナ frontend が動いている" running "${st:-なし}"

docker compose run --rm seed >>"$LOG" 2>&1 && pass "サンプルを入れる（seed）" || fail "サンプルを入れる（seed）" "log.txt を見る"

# ---------- 各サービスの動作確認 ----------
check "api    :8787/healthz" 200 "$(code http://localhost:8787/healthz)"
check "auth   :4100/healthz" 200 "$(code http://localhost:4100/healthz)"
check "excel  :8001/healthz" 200 "$(code http://localhost:8001/healthz)"
check "画面   :8000/" 200 "$(code $BASE/)"
check "画面のアセット（Excel のテンプレート）が読める" 200 "$(code $BASE/assets/assets/data/format_skill_sheet.xlsx)"
check "画面のアセット（PDF のフォント）が読める" 200 "$(code $BASE/assets/assets/fonts/ipagp.ttf)"
check "nginx → api（:8000/healthz）" 200 "$(code $BASE/healthz)"

# ---------- ログイン（nginx → auth → Auth Emulator） ----------
login=$(curl -s -X POST $BASE/auth/login -H 'Content-Type: application/json' \
  -d '{"email":"sample@example.com","password":"sample-password"}')
TOKEN=$(printf '%s' "$login" | sed -nE 's/.*"idToken":"([^"]+)".*/\1/p')
if [ -n "$TOKEN" ]; then pass "ログイン（サンプルの利用者）"; else fail "ログイン（サンプルの利用者）" "トークンがない"; log "login: $login"; fi
AUTH=(-H "Authorization: Bearer $TOKEN")
J=(-H 'Content-Type: application/json')

contains "認証：自分の情報（/auth/me）" 'sample@example.com' "$(curl -s $BASE/auth/me "${AUTH[@]}")"
me=$(curl -s $BASE/api/me "${AUTH[@]}"); log "api/me: $me"
contains "API：自分の情報（/api/me）" '"slug":"sample"' "$me"
check "API：トークンなしは 401" 401 "$(code $BASE/api/me)"
check "認証：パスワードが違えば 401" 401 "$(code -X POST $BASE/auth/login "${J[@]}" -d '{"email":"sample@example.com","password":"wrong-password"}')"

# ---------- 公開ページ・名前・公開（段階 5-1） ----------
check "公開ページ（/api/public/sample）" 200 "$(code $BASE/api/public/sample)"
public=$(curl -s $BASE/api/public/sample)
if printf '%s' "$public" | grep -qE 'furigana|station'; then fail "公開ページにスキルシートだけの項目がない" "入っている"; else pass "公開ページにスキルシートだけの項目がない"; fi
check "予約されている名前は 400" 400 "$(code -X PUT $BASE/api/me/slug "${AUTH[@]}" "${J[@]}" -d '{"slug":"api"}')"
check "名前を変える（sample-2）" 200 "$(code -X PUT $BASE/api/me/slug "${AUTH[@]}" "${J[@]}" -d '{"slug":"sample-2"}')"
check "前の名前は 404" 404 "$(code $BASE/api/public/sample)"
check "新しい名前で開ける" 200 "$(code $BASE/api/public/sample-2)"
check "公開を止める" 200 "$(code -X DELETE $BASE/api/me/publish "${AUTH[@]}")"
check "止めたら 404" 404 "$(code $BASE/api/public/sample-2)"
contains "公開する（版が 2）" '"publishedVersion":2' "$(curl -s -X POST $BASE/api/me/publish "${AUTH[@]}" "${J[@]}" -d '{}')"
check "名前を元に戻す（sample）" 200 "$(code -X PUT $BASE/api/me/slug "${AUTH[@]}" "${J[@]}" -d '{"slug":"sample"}')"

# ---------- 見る人向けのスキルシート（段階 6。nginx → api → excel。形は本人の［ダウンロード］と同じ） ----------
pdf_code=$(curl -s -D "$OUT/pdf-headers.txt" -o "$OUT/skill-sheet.pdf" -w '%{http_code}' $BASE/api/public/sample/skill-sheet.pdf)
check "見る人向けの PDF（/api/public/sample/skill-sheet.pdf）" 200 "$pdf_code"
contains "PDF の Content-Type" 'application/pdf' "$(cat "$OUT/pdf-headers.txt")"
contains "PDF の中身が PDF" '%PDF' "$(head -c 8 "$OUT/skill-sheet.pdf")"
xlsx_code=$(curl -s -o "$OUT/skill-sheet.xlsx" -w '%{http_code}' $BASE/api/public/sample/skill-sheet.xlsx)
check "見る人向けの Excel（/api/public/sample/skill-sheet.xlsx）" 200 "$xlsx_code"
contains "Excel の中身が .xlsx（zip）" 'PK' "$(head -c 2 "$OUT/skill-sheet.xlsx")"
check "ない名前の PDF は 404" 404 "$(code $BASE/api/public/none/skill-sheet.pdf)"
check "excel はトークンなしでは断る（401）" 401 "$(code -X POST http://localhost:8001/render/skill-sheet.pdf "${J[@]}" -d '{"data":{}}')"

# ---------- FastAPI のテスト（コンテナの中で pytest） ----------
echo "FastAPI のテストを動かしています…"
# 本物のコマンドのテスト（tests/test_real_sheet.py）は CI で動かす。ここでは偽物のコマンドのテストだけ
if docker run --rm -v "$PWD":/repo -w /repo/services/excel-fastapi python:3.12-slim sh -c \
  "pip install -q --root-user-action=ignore -r requirements-dev.txt && pytest -p no:cacheprovider --cov=app --cov-branch --cov-report=term-missing --cov-fail-under=90" \
  >>"$LOG" 2>&1; then
  pass "FastAPI の pytest（網羅率 90% 以上）"
else
  fail "FastAPI の pytest（網羅率 90% 以上）" "log.txt を見る"
fi
find services/excel-fastapi -name __pycache__ -type d -prune -exec rm -rf {} + 2>/dev/null
rm -f services/excel-fastapi/.coverage

# ---------- 各コンテナのログ（失敗の理由を見るため。最後の 40 行） ----------
for svc in frontend api auth excel; do
  log "--- docker compose logs $svc"
  docker compose logs --no-color --tail 40 "$svc" >>"$LOG" 2>&1
done
log "--- docker compose ps（最後）"; docker compose ps >>"$LOG" 2>&1

# ---------- 後片付け ----------
docker compose run --rm seed >>"$LOG" 2>&1

echo "== FAIL：$FAILS 件（結果：${RESULT}、細かい出力：${LOG}）==" | tee -a "$RESULT"
exit "$FAILS"
