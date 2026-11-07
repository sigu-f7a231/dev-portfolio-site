"""本物のスキルシートのコマンドで作る（Dart のコマンドがあるときだけ。CI の excel-fastapi では作ってから動かす）

  SKILL_SHEET_REAL=1 SKILL_SHEET_CMD=/path/skill_sheet SKILL_SHEET_TEMPLATE=… FONT_PATH=… pytest

確かめること：形は本人がダウンロードするもの（Excel のテンプレート）と同じで、公開ページのデータの中身が入り、
スキルシートだけの項目は入らない
"""

from __future__ import annotations

import asyncio
import copy
import io
import os
from datetime import date

import pytest

from app import sheet

from .conftest import pdf_text

pytestmark = pytest.mark.skipif(not os.environ.get("SKILL_SHEET_REAL"), reason="本物のコマンドがない（SKILL_SHEET_REAL）")


def _with_secrets(public_data):
    data = copy.deepcopy(public_data)
    data["profile"]["sheet"] = {"furigana": "さんぷる たろう", "station": "架空駅", "birthday": "1990-04-01"}
    return data


def test_Excel_テンプレートの形のまま中身が入り_スキルシートだけの項目は空(public_data):
    from openpyxl import load_workbook

    xlsx = asyncio.run(sheet.build("xlsx", _with_secrets(public_data), created=date(2026, 11, 8)))
    ws = load_workbook(io.BytesIO(xlsx)).active
    values = [str(c.value) for row in ws.iter_rows() for c in row if c.value is not None]
    text = "\n".join(values)
    assert ws["A1"].value.strip() == "Skill Sheet"
    assert ws["E5"].value == "サンプル 太郎"
    assert "サンプル・ワークプロジェクト" in text
    assert "サンプル・プライベートプロジェクト" in text
    for secret in ["さんぷる", "架空駅", "1990"]:
        assert secret not in text


def test_PDF_Excel_の見た目のまま_Skill_Sheet_の見出し_名前_案件(public_data):
    pdf = asyncio.run(sheet.build("pdf", _with_secrets(public_data), created=date(2026, 11, 8)))
    assert pdf.startswith(b"%PDF")
    text = pdf_text(pdf).replace("\n", "")
    for expected in ["Skill Sheet", "サンプル 太郎", "サンプル・ワークプロジェクト", "PostgreSQL"]:
        assert expected in text, expected
    for secret in ["さんぷる", "架空駅", "1990"]:
        assert secret not in text
