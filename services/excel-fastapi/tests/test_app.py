"""ルート（app/main.py）のテスト。TestClient で呼ぶ（サーバーは起動しない）。スキルシートのコマンドは偽物"""

from __future__ import annotations

import json

import pytest
from fastapi.testclient import TestClient

from app import main

from .conftest import fake_output


@pytest.fixture
def client(fake_sheet) -> TestClient:
    fake_sheet.delenv("INTERNAL_TOKEN", raising=False)
    return TestClient(main.app)


def test_healthz(client):
    res = client.get("/healthz")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}
    assert res.headers["cache-control"] == "no-store"


@pytest.mark.parametrize(
    ("path", "media", "fmt"),
    [
        ("/render/skill-sheet.pdf", "application/pdf", "pdf"),
        ("/render/skill-sheet.xlsx", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "xlsx"),
    ],
)
def test_公開ページのデータを送ると_スキルシートが返る(client, public_data, path, media, fmt):
    res = client.post(path, json={"data": public_data})
    assert res.status_code == 200
    assert res.headers["content-type"] == media
    assert res.headers["cache-control"] == "no-store"
    out = fake_output(res.content)
    assert out["args"][1] == fmt
    assert out["input"]["data"] == public_data
    assert len(out["input"]["today"]) == 10  # 日本時間の今日（YYYY-MM-DD）


@pytest.mark.parametrize(
    ("body", "status", "code"),
    [
        (b"{bad json", 400, "invalid_request"),
        (json.dumps([1]).encode(), 400, "invalid_request"),
        (json.dumps({"data": "x"}).encode(), 400, "invalid_request"),
        (b"x" * (main.MAX_BODY_BYTES + 1), 413, "too_large"),
    ],
)
def test_異常系_形が違う_大きすぎる(client, body, status, code):
    res = client.post("/render/skill-sheet.pdf", content=body, headers={"Content-Type": "application/json"})
    assert res.status_code == status
    assert res.json()["error"]["code"] == code


def test_INTERNAL_TOKEN_があれば_同じ値のときだけ受け付ける(client, fake_sheet, public_data):
    fake_sheet.setenv("INTERNAL_TOKEN", "secret")
    assert client.post("/render/skill-sheet.pdf", json={"data": public_data}).status_code == 401
    bad = client.post("/render/skill-sheet.xlsx", json={"data": public_data}, headers={"X-Internal-Token": "other"})
    assert bad.status_code == 401
    assert bad.json()["error"]["code"] == "unauthorized"
    ok = client.post("/render/skill-sheet.pdf", json={"data": public_data}, headers={"X-Internal-Token": "secret"})
    assert ok.status_code == 200


def test_ないパス_使えないメソッドは同じ形のエラー(client):
    res = client.get("/nope")
    assert res.status_code == 404
    assert res.json()["error"]["code"] == "not_found"
    res = client.get("/render/skill-sheet.pdf")
    assert res.status_code == 405
    assert res.json()["error"]["code"] == "method_not_allowed"


def test_コマンド_ファイルがなければ_503(client, fake_sheet, public_data):
    fake_sheet.setenv("FAKE_SHEET_MODE", "nofile")
    res = client.post("/render/skill-sheet.pdf", json={"data": public_data})
    assert res.status_code == 503
    assert res.json()["error"]["code"] == "not_configured"


def test_作れなければ_500(client, fake_sheet, public_data):
    fake_sheet.setenv("FAKE_SHEET_MODE", "fail")
    res = client.post("/render/skill-sheet.pdf", json={"data": public_data})
    assert res.status_code == 500
    assert res.json()["error"]["code"] == "render_failed"


def test_ログ_1_リクエスト_1_行の_JSON_中身は書かない(client, capsys, public_data):
    client.post("/render/skill-sheet.pdf", json={"data": public_data})
    lines = [json.loads(line) for line in capsys.readouterr().out.splitlines() if line.startswith("{")]
    assert lines[-1]["httpRequest"]["status"] == 200
    assert lines[-1]["severity"] == "INFO"
    assert "サンプル" not in json.dumps(lines, ensure_ascii=False)
