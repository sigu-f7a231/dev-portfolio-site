# frontend/Dockerfile
# 1. Flutter で Web をビルド
# 2. nginx で配信し、/api/ と /healthz は API（services/api-hono）へ転送する（本番の Cloudflare Worker と同じ役割）
ARG FLUTTER_VERSION=3.41.6

FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build
WORKDIR /app

# 依存関係だけ先に取得（pubspec が変わらなければキャッシュが効く）
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
# BASE_HREF … 配信するパス（GitHub Pages なら /dev-portfolio-site/）
ARG BASE_HREF=/
RUN flutter build web --release --base-href "${BASE_HREF}"

FROM nginx:1.27-alpine
# templates/*.template は起動時に環境変数（BACKEND_ORIGIN）を埋め込んで conf.d に置かれる
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html
ENV BACKEND_ORIGIN=http://api:8787
EXPOSE 80
