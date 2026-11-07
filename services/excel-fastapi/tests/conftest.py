"""テストの道具：公開ページのデータ（firebase/seed/sample.json と同じ架空の人。個人の情報は入れない）と、偽のコマンド"""

from __future__ import annotations

import io
import json
import shlex
import sys
from pathlib import Path
from typing import Any

import pytest
from pypdf import PdfReader


FAKE = Path(__file__).with_name("fake_skill_sheet.py")


def fake_output(content: bytes) -> dict[str, Any]:
    """偽のコマンドが返したもの（受け取った引数と入力）"""
    assert content.startswith(b"FAKE")
    return json.loads(content[4:])


@pytest.fixture
def fake_sheet(monkeypatch):
    """スキルシートのコマンドを偽物にする。FAKE_SHEET_MODE で動きを変えられる"""
    monkeypatch.setenv("SKILL_SHEET_CMD", f"{shlex.quote(sys.executable)} {shlex.quote(str(FAKE))}")
    monkeypatch.setenv("SKILL_SHEET_TEMPLATE", "/tmp/template.xlsx")
    monkeypatch.setenv("FONT_PATH", "/tmp/font.ttf")
    monkeypatch.delenv("FAKE_SHEET_MODE", raising=False)
    return monkeypatch


def pdf_text(pdf: bytes) -> str:
    return "\n".join(page.extract_text() or "" for page in PdfReader(io.BytesIO(pdf)).pages)


def pdf_pages(pdf: bytes) -> int:
    return len(PdfReader(io.BytesIO(pdf)).pages)


@pytest.fixture
def public_data() -> dict[str, Any]:
    """services/api-hono の publicDataOf の結果と同じ形（sheet は入っていない）"""
    return {
        "schemaVersion": 1,
        "profile": {
            "home": {"name": "サンプル 太郎", "role": "Web / モバイルエンジニア", "tagline": "Flutter と Dart を中心に開発しています。"},
            "about": {
                "intro": "受託開発の会社で Web アプリを担当しています。",
                "domains": ["Web", "モバイル"],
                "strengths": "チーム開発",
            },
        },
        "skills": {
            "recentTech": {"言語": ["Dart", "TypeScript"], "FW": ["Flutter"]},
            "pastTech": {"言語": ["Python"]},
        },
        "projects": [
            {
                "id": "p2",
                "kind": "work",
                "order": 1,
                "title": "二つ目の業務",
                "period": {"start": "2024-01", "end": None},
                "tech": {"skills": ["Go"]},
            },
            {
                "id": "p1",
                "kind": "work",
                "order": 0,
                "title": "サンプル・ワークプロジェクト",
                "description": "チーム開発で設計から実装まで担当",
                "role": ["PG"],
                "scale": "5 名",
                "period": {"start": "2023-04", "end": "2023-09"},
                "link": "https://example.com/work",
                "tech": {"skills": ["Python"], "db": ["PostgreSQL"], "tools": ["利用なし"]},
                "workflow": {"basic_design": True, "detailed_design": True, "system_test": False},
            },
            {
                "id": "p3",
                "kind": "private",
                "order": 0,
                "title": "サンプル・プライベートプロジェクト",
                "period": {"start": "2024-01", "end": None},
                "tech": {"frontend_frameworks": ["React"]},
            },
        ],
        "display": {
            "sections": [{"id": "about", "visible": True}, {"id": "projects", "visible": True}],
            "allowSheetDownload": True,
        },
    }
