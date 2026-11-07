"""スキルシートのコマンドの呼び出し（app/sheet.py）のテスト。コマンドは偽物（tests/fake_skill_sheet.py）"""

from __future__ import annotations

import asyncio
from datetime import date

import pytest

from app import sheet

from .conftest import fake_output


def run(coro):
    return asyncio.run(coro)


def test_PDF_テンプレートとフォントを渡し_データと作成日を送る(fake_sheet, public_data):
    out = fake_output(run(sheet.build("pdf", public_data, created=date(2026, 11, 8))))
    assert out["args"] == ["--format", "pdf", "--template", "/tmp/template.xlsx", "--font", "/tmp/font.ttf"]
    assert out["input"] == {"data": public_data, "today": "2026-11-08"}


def test_Excel_フォントは渡さない(fake_sheet, public_data):
    out = fake_output(run(sheet.build("xlsx", public_data, created=date(2026, 1, 2))))
    assert out["args"] == ["--format", "xlsx", "--template", "/tmp/template.xlsx"]
    assert out["input"]["today"] == "2026-01-02"


def test_既定の場所_Docker_の中(monkeypatch):
    for key in ["SKILL_SHEET_CMD", "SKILL_SHEET_TEMPLATE", "FONT_PATH"]:
        monkeypatch.delenv(key, raising=False)
    assert sheet._command("pdf") == [
        "/usr/local/bin/skill_sheet",
        "--format",
        "pdf",
        "--template",
        "/opt/skill-sheet/format_skill_sheet.xlsx",
        "--font",
        "/opt/skill-sheet/ipagp.ttf",
    ]


def test_異常系_コマンドがない_ファイルがないは_SheetUnavailable(fake_sheet, public_data, tmp_path):
    fake_sheet.setenv("SKILL_SHEET_CMD", str(tmp_path / "none"))
    with pytest.raises(sheet.SheetUnavailable):
        run(sheet.build("pdf", public_data, created=date.today()))
    not_executable = tmp_path / "plain.txt"
    not_executable.write_text("x")
    fake_sheet.setenv("SKILL_SHEET_CMD", str(not_executable))
    with pytest.raises(sheet.SheetUnavailable):
        run(sheet.build("pdf", public_data, created=date.today()))


def test_異常系_ファイルを読めないと言われたら_SheetUnavailable(fake_sheet, public_data):
    fake_sheet.setenv("FAKE_SHEET_MODE", "nofile")
    with pytest.raises(sheet.SheetUnavailable, match="ファイルを読めません"):
        run(sheet.build("pdf", public_data, created=date.today()))


def test_異常系_失敗したら理由つきの_SheetFailed(fake_sheet, public_data):
    fake_sheet.setenv("FAKE_SHEET_MODE", "fail")
    with pytest.raises(sheet.SheetFailed, match="公開ページのデータ"):
        run(sheet.build("pdf", public_data, created=date.today()))


def test_異常系_時間切れは止めて_SheetFailed(fake_sheet, public_data):
    fake_sheet.setenv("FAKE_SHEET_MODE", "slow")
    fake_sheet.setattr(sheet, "TIMEOUT_SECONDS", 0.5)
    with pytest.raises(sheet.SheetFailed, match="時間内"):
        run(sheet.build("pdf", public_data, created=date.today()))
