# services/api-hono/Dockerfile
#
# Node 22 で TypeScript をそのまま動かす（型を外して実行。ビルドの手順はない）
# - 依存は本番用だけ（hono・@hono/node-server）
# - package-lock.json があれば npm ci（版をそろえる）。まだなければ npm install
FROM node:22-bookworm-slim

WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi \
    && npm cache clean --force

# 下で node ユーザーに切り替えて動かすので、node が読めるようにする
# （手元のファイルが自分だけ読める権限（600）でも、そのまま写すと node から読めない）
COPY --chown=node:node src ./src

ENV PORT=8787
EXPOSE 8787
USER node
CMD ["node", "src/server.ts"]
