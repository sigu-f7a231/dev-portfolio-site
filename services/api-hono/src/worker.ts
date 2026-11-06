// src/worker.ts
//
// Cloudflare Workers で動かす入口（wrangler dev で確かめる。本番の置き場所は docs/plan/decisions.md の D-02 で決める）
// - 設定は Workers の env（wrangler.toml の [vars]）から作る
// - 本物の Firestore につなぐには、サービスアカウントの JWT で取るアクセストークンが要る（まだ作っていない）。
//   今は Emulator（FIRESTORE_EMULATOR_HOST があるとき）だけで動く
import { configFrom } from './config.ts';
import { buildApp } from './setup.ts';

type WorkerEnv = Record<string, string | undefined>;

let cached: { key: string; app: ReturnType<typeof buildApp> } | undefined;

export default {
  fetch(request: Request, env: WorkerEnv, ctx: unknown) {
    const key = JSON.stringify(env);
    if (!cached || cached.key !== key) {
      const config = configFrom(env);
      if (!config.firestoreEmulatorHost) {
        return new Response(
          JSON.stringify({ error: { code: 'not_configured', message: 'Workers では今は Emulator だけで動きます' } }),
          { status: 503, headers: { 'Content-Type': 'application/json' } },
        );
      }
      cached = { key, app: buildApp(config) };
    }
    return cached.app.fetch(request, env, ctx as never);
  },
};
