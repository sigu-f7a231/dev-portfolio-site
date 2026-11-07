"""テスト用の偽のスキルシートのコマンド（本物は frontend/bin/skill_sheet.dart を dart compile exe したもの）

FAKE_SHEET_MODE で動きを変える
  ok（既定）… "FAKE" ＋ 受け取った引数と入力の JSON を返す
  fail      … 理由を書いて 2 で終わる
  nofile    … 「ファイルを読めません」で 2 で終わる（テンプレート・フォントがない）
  slow      … 時間切れを確かめるため、10 秒待つ
"""

import json
import os
import sys
import time

mode = os.environ.get("FAKE_SHEET_MODE", "ok")
data = sys.stdin.buffer.read()
if mode == "fail":
    sys.stderr.write("入力は { \"data\": 公開ページのデータ } の形にしてください\n")
    sys.exit(2)
if mode == "nofile":
    sys.stderr.write("ファイルを読めません：/opt/skill-sheet/ipagp.ttf\n")
    sys.exit(2)
if mode == "slow":
    time.sleep(10)
sys.stdout.buffer.write(b"FAKE" + json.dumps({"args": sys.argv[1:], "input": json.loads(data)}, ensure_ascii=False).encode())
