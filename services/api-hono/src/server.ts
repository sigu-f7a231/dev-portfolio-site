// src/server.ts
//
// Node で起動する（docker compose・Cloud Run）。node src/server.ts（Node 22 は TypeScript の型を外してそのまま動かせる）
// - SIGTERM / SIGINT で、受け付け中のリクエストを終えてから止まる（Cloud Run は止めるときに SIGTERM を送る）
// - node src/server.ts healthcheck … 自分の /healthz を呼び、成功なら 0 で終わる（コンテナのヘルスチェック用）
import { serve } from '@hono/node-server';

import { configFrom } from './config.ts';
import { logEntry } from './log.ts';
import { buildApp } from './setup.ts';

const config = configFrom(process.env);

if (process.argv[2] === 'healthcheck') {
  try {
    const res = await fetch(`http://127.0.0.1:${config.port}/healthz`);
    process.exit(res.ok ? 0 : 1);
  } catch {
    process.exit(1);
  }
}

const app = buildApp(config);
const server = serve({ fetch: app.fetch, port: config.port, hostname: '0.0.0.0' }, (info) => {
  logEntry(console.log, 'INFO', `api-hono を起動しました（:${info.port}）`, {
    projectId: config.projectId,
    emulator: Boolean(config.firestoreEmulatorHost),
  });
});

for (const signal of ['SIGTERM', 'SIGINT'] as const) {
  process.on(signal, () => {
    logEntry(console.log, 'INFO', `${signal} を受け取ったので止めます`);
    server.close(() => process.exit(0));
    setTimeout(() => process.exit(0), 10_000).unref(); // 10 秒で終わらなければ止める
  });
}
