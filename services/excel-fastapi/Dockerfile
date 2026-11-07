# services/excel-fastapi … 公開ページを見る人向けのスキルシート（Excel・PDF）を作る
# 形は本人がダウンロードするものと同じ（Excel のテンプレート）。作るのは Dart のコマンド（frontend/bin/skill_sheet.dart）
# ビルドには frontend も要る（compose.yaml の additional_contexts で frontend という名前で渡す）
#   docker build --build-context frontend=../../frontend .

# ---------- 1. スキルシートのコマンドを作る（Dart） ----------
# Dart の版は stable（使うパッケージの版は dart/pubspec.yaml で frontend と同じに固定）
FROM dart:stable AS sheet
COPY dart/ /build/
COPY --from=frontend lib /frontend/lib
COPY --from=frontend bin /frontend/bin
RUN sh /build/build.sh /frontend /out/skill_sheet

# ---------- 2. FastAPI ----------
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8001 \
    SKILL_SHEET_CMD=/usr/local/bin/skill_sheet \
    SKILL_SHEET_TEMPLATE=/opt/skill-sheet/format_skill_sheet.xlsx \
    FONT_PATH=/opt/skill-sheet/ipagp.ttf

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# テンプレートとフォントは frontend と同じファイル（個人の情報は入っていない。assets/profile/ は使わない）
COPY --from=sheet /out/skill_sheet /usr/local/bin/skill_sheet
COPY --from=frontend --chmod=644 assets/data/format_skill_sheet.xlsx /opt/skill-sheet/format_skill_sheet.xlsx
COPY --from=frontend --chmod=644 assets/fonts/ipagp.ttf /opt/skill-sheet/ipagp.ttf
# 手元のファイルの権限（600 など）によらず、nobody が読めるように
COPY --chown=nobody:nogroup app ./app

USER nobody
EXPOSE 8001
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s --retries=5 \
  CMD python -c "import os, urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ[\"PORT\"]}/healthz', timeout=2)"
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port ${PORT} --no-access-log"]
