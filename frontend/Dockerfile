# frontend/Dockerfile
# 1. Flutter で Web をビルド
# 2. nginx で配信し、/api/ と /healthz は API（services/api-hono）へ、/auth/ は認証（services/auth-phoenix）へ転送する（本番の Cloudflare Worker と同じ役割）
ARG FLUTTER_VERSION=3.41.6

FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION} AS build
WORKDIR /app

# 依存関係だけ先に取得（pubspec が変わらなければキャッシュが効く）
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
# BASE_HREF … 配信するパス（GitHub Pages なら /dev-portfolio-site/）
ARG BASE_HREF=/
# true にすると、ログイン・マイページ（/login・/me）を開ける（compose.yaml では true。本番の公開ページは false のまま）
ARG ENABLE_ACCOUNT=false
RUN flutter build web --release --base-href "${BASE_HREF}" --dart-define=ENABLE_ACCOUNT=${ENABLE_ACCOUNT} \
 # 手元のファイルの権限（600 など）がアセットに残ると、nginx が読めずに 403 になる。誰でも読めるようにする
 && chmod -R a+rX build/web

FROM nginx:1.27-alpine
# templates/*.template は起動時に環境変数（BACKEND_ORIGIN・AUTH_ORIGIN・NGINX_RESOLVER）を埋め込んで conf.d に置かれる
COPY nginx/default.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html
ENV NGINX_RESOLVER=127.0.0.11 \
    BACKEND_ORIGIN=http://api:8787 \
    AUTH_ORIGIN=http://auth:4100
EXPOSE 80
