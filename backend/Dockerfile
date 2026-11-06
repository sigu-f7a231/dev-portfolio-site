# backend/Dockerfile
# Dart の公式イメージでネイティブの実行ファイルにし、scratch（最小限の実行環境だけ）で動かす。
# イメージは 10MB 前後になり、Cloud Run の起動も速い。
ARG DART_VERSION=3.11

FROM dart:${DART_VERSION} AS build
WORKDIR /app

# 依存関係だけ先に取得（pubspec が変わらなければキャッシュが効く）
COPY pubspec.* ./
RUN dart pub get

COPY . .
RUN dart pub get --offline \
 && dart compile exe bin/server.dart -o bin/server \
 && chmod -R a+rX data

FROM scratch
# dart compile exe の実行に必要な最小限のライブラリ（公式イメージが /runtime に用意している）
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/server
# 既定のデータ（docker compose ではホストの backend/data を上からマウントする）
COPY --from=build /app/data /data

ENV PORT=8080 \
    DATA_DIR=/data
EXPOSE 8080
USER 65532:65532

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/app/bin/server", "healthcheck"]

CMD ["/app/bin/server"]
