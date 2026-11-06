# firebase/Dockerfile
#
# Firebase Emulator（Auth・Firestore・確認用の画面）をローカルで動かすイメージ
# - firebase-tools 15 は Java 21 以上が必要なので、Node のイメージに Temurin の JRE（Java 21）を入れる
# - エミュレーター本体（Firestore の jar・確認用の画面）はビルドのときに取っておき、起動のたびに取りに行かない
# - データは /data（compose で ./firebase/emulator-data をつなぐ）。終了時に書き出し、次の起動で読み込む（entrypoint.sh）
FROM eclipse-temurin:21-jre AS jre

FROM node:22-bookworm-slim

COPY --from=jre /opt/java/openjdk /opt/java/openjdk
ENV JAVA_HOME=/opt/java/openjdk \
    PATH=/opt/java/openjdk/bin:$PATH

# 版は固定する（上げるときは https://firebase.google.com/support/release-notes/cli を見る）
ARG FIREBASE_TOOLS_VERSION=15.34.0
RUN npm install -g firebase-tools@${FIREBASE_TOOLS_VERSION} \
    && npm cache clean --force \
    && firebase setup:emulators:firestore \
    && firebase setup:emulators:ui

WORKDIR /firebase
COPY firebase.json firestore.rules entrypoint.sh ./
RUN chmod +x entrypoint.sh

# 4001 確認用の画面・4400 ハブ・8080 Firestore・9099 Auth・9150 確認用の画面が Firestore を見るための WebSocket
EXPOSE 4001 4400 8080 9099 9150
ENTRYPOINT ["./entrypoint.sh"]
