"""スキルシート（Excel・PDF）を作るコマンドを呼ぶ

形は本人がダウンロードするものと同じ（Excel のテンプレート frontend/assets/data/format_skill_sheet.xlsx）。
作るのは Dart のコマンド（frontend/bin/skill_sheet.dart を dart compile exe したもの）。ブラウザと同じ処理なので、
見た目・並び・書き方が本人の［ダウンロード］とそろう（Python で作り直さない。docs/plan/excel.md）

環境変数（Docker では既定のまま）
  SKILL_SHEET_CMD       コマンド（既定 /usr/local/bin/skill_sheet）。手元では "dart run ../../frontend/bin/skill_sheet.dart" など
  SKILL_SHEET_TEMPLATE  Excel のテンプレート（既定 /opt/skill-sheet/format_skill_sheet.xlsx）
  FONT_PATH             PDF の日本語フォント（既定 /opt/skill-sheet/ipagp.ttf。IPA P ゴシック）
"""

from __future__ import annotations

import asyncio
import json
import os
import shlex
from datetime import date
from typing import Any, Literal

Format = Literal["pdf", "xlsx"]

DEFAULT_CMD = "/usr/local/bin/skill_sheet"
DEFAULT_TEMPLATE = "/opt/skill-sheet/format_skill_sheet.xlsx"
DEFAULT_FONT = "/opt/skill-sheet/ipagp.ttf"

#: 1 回の上限（秒）。PDF は 200 件でも数秒の見込み
TIMEOUT_SECONDS = 30

#: 同時に作る数（メモリを使いすぎないように。Cloud Run の 1 インスタンス 512 MiB を想定）
_slots = asyncio.Semaphore(2)


class SheetUnavailable(RuntimeError):
    """コマンド・テンプレート・フォントがない（設定の誤り）"""


class SheetFailed(RuntimeError):
    """コマンドが失敗した・時間切れ"""


def _command(fmt: Format) -> list[str]:
    cmd = shlex.split(os.environ.get("SKILL_SHEET_CMD", DEFAULT_CMD))
    template = os.environ.get("SKILL_SHEET_TEMPLATE", DEFAULT_TEMPLATE)
    args = [*cmd, "--format", fmt, "--template", template]
    if fmt == "pdf":
        args += ["--font", os.environ.get("FONT_PATH", DEFAULT_FONT)]
    return args


async def build(fmt: Format, data: dict[str, Any], *, created: date) -> bytes:
    """公開ページのデータ → スキルシートのバイト列"""
    payload = json.dumps({"data": data, "today": created.isoformat()}, ensure_ascii=False).encode()
    async with _slots:
        try:
            proc = await asyncio.create_subprocess_exec(
                *_command(fmt),
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
            )
        except (FileNotFoundError, PermissionError) as e:
            raise SheetUnavailable(f"スキルシートを作るコマンドがありません：{e}") from e
        try:
            out, err = await asyncio.wait_for(proc.communicate(payload), timeout=TIMEOUT_SECONDS)
        except asyncio.TimeoutError as e:
            proc.kill()
            await proc.wait()
            raise SheetFailed("時間内に作れませんでした") from e
    if proc.returncode != 0:
        message = err.decode(errors="replace").strip()[-300:]
        if "ファイルを読めません" in message:
            raise SheetUnavailable(message)
        raise SheetFailed(message or f"終わりの数字 {proc.returncode}")
    return out
