"""excel-fastapi のルート

  GET  /healthz                   … 動作確認（コンテナのヘルスチェック）
  POST /render/skill-sheet.pdf    … 公開ページのデータ（{"data"}）→ スキルシートの PDF（Excel の見た目のまま）
  POST /render/skill-sheet.xlsx   … 同じく Excel

- 形は本人がダウンロードするスキルシートと同じ（app/sheet.py。Dart の同じ処理で作る）
- 呼ぶのは API（services/api-hono）だけ。画面（nginx）からは直接つながない。Firestore にもつながない（D-05：Firestore は Hono だけ）
- INTERNAL_TOKEN があれば、X-Internal-Token が同じときだけ受け付ける（ほかから直接呼ばせない）
- エラーは {"error": {"code", "message"}}（ほかのサービスと同じ形）
- 1 リクエスト 1 行の JSON ログ（Cloud Logging の構造化ログ）。中身（名前など）は書かない
"""

from __future__ import annotations

import hmac
import json
import os
import time
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse, Response
from starlette.exceptions import HTTPException as StarletteHTTPException

from . import sheet

#: 受け取る JSON の上限（Firestore の 1 文書の上限 1 MiB より小さく）
MAX_BODY_BYTES = 1_000_000
JST = timezone(timedelta(hours=9))

MEDIA_TYPES = {
    "pdf": "application/pdf",
    "xlsx": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
}


def _log(severity: str, message: str, **fields: Any) -> None:
    """1 行の JSON を標準出力に（Cloud Run がそのまま Cloud Logging に送る）"""
    print(json.dumps({"severity": severity, "message": message, **fields}, ensure_ascii=False), flush=True)


def error(status: int, code: str, message: str) -> JSONResponse:
    return JSONResponse({"error": {"code": code, "message": message}}, status_code=status)


app = FastAPI(title="excel-fastapi", docs_url=None, redoc_url=None, openapi_url=None)


@app.middleware("http")
async def request_log(request: Request, call_next):
    started = time.perf_counter()
    response = await call_next(request)
    status = response.status_code
    _log(
        "ERROR" if status >= 500 else "WARNING" if status >= 400 else "INFO",
        f"{request.method} {request.url.path} {status}",
        httpRequest={
            "requestMethod": request.method,
            "requestUrl": request.url.path,
            "status": status,
            "latency": f"{time.perf_counter() - started:.3f}s",
        },
    )
    return response


@app.exception_handler(StarletteHTTPException)
async def http_error(_request: Request, exc: StarletteHTTPException) -> JSONResponse:
    if exc.status_code == 404:
        return error(404, "not_found", "ページがありません")
    if exc.status_code == 405:
        return error(405, "method_not_allowed", "このメソッドは使えません")
    return error(exc.status_code, "http_error", str(exc.detail))  # pragma: no cover（ほかの状態は出さない）


@app.get("/healthz")
async def healthz() -> JSONResponse:
    return JSONResponse({"status": "ok"}, headers={"Cache-Control": "no-store"})


async def _render(request: Request, fmt: sheet.Format) -> Response:
    token = os.environ.get("INTERNAL_TOKEN")
    if token and not hmac.compare_digest(request.headers.get("X-Internal-Token", ""), token):
        return error(401, "unauthorized", "呼び出し元を確かめられません")

    body = await request.body()
    if len(body) > MAX_BODY_BYTES:
        return error(413, "too_large", "送るデータが大きすぎます")
    try:
        payload = json.loads(body)
    except (ValueError, UnicodeDecodeError):
        return error(400, "invalid_request", "JSON として読めません")
    if not isinstance(payload, dict) or not isinstance(payload.get("data"), dict):
        return error(400, "invalid_request", '{ "data": 公開ページのデータ } の形で送ってください')

    try:
        content = await sheet.build(fmt, payload["data"], created=datetime.now(JST).date())
    except sheet.SheetUnavailable as e:
        _log("ERROR", str(e))
        return error(503, "not_configured", "スキルシートを作る準備ができていません")
    except sheet.SheetFailed as e:
        _log("ERROR", f"スキルシートを作れませんでした：{e}")
        return error(500, "render_failed", "スキルシートを作れませんでした")
    return Response(content, media_type=MEDIA_TYPES[fmt], headers={"Cache-Control": "no-store"})


@app.post("/render/skill-sheet.pdf")
async def render_pdf(request: Request) -> Response:
    return await _render(request, "pdf")


@app.post("/render/skill-sheet.xlsx")
async def render_xlsx(request: Request) -> Response:
    return await _render(request, "xlsx")
