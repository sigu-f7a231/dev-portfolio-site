#!/bin/sh
# firebase/entrypoint.sh
#
# Firebase Emulator を起動する
# - 前に書き出したデータ（/data/firebase-export-metadata.json があるとき）を読み込む
# - 止めたとき（docker compose stop / down。compose は SIGINT を送る）にデータを /data に書き出す
# - プロジェクトは demo- で始まる名前（本物の Firebase のプロジェクトにはつながらない）
set -eu

DATA_DIR="${EMULATOR_DATA_DIR:-/data}"
PROJECT="${FIREBASE_PROJECT:-demo-dev-portfolio}"

set -- emulators:start --project "$PROJECT" --only auth,firestore --export-on-exit "$DATA_DIR"
if [ -f "$DATA_DIR/firebase-export-metadata.json" ]; then
  echo "前に書き出したデータを読み込みます（$DATA_DIR）"
  set -- "$@" --import "$DATA_DIR"
else
  echo "書き出したデータがないので、空で始めます（サンプルは docker compose run --rm seed で入れる）"
fi

exec firebase "$@"
