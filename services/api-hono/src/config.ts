// src/config.ts
//
// 設定（環境変数）。Node では process.env、Workers では env（wrangler.toml・シークレット）から作る
//   PORT                          待ち受けるポート（Node だけ。既定 8787）
//   FIREBASE_PROJECT              Firebase のプロジェクト（既定 demo-dev-portfolio。demo- で始まる名前は Emulator だけ）
//   FIRESTORE_EMULATOR_HOST       あれば Firestore Emulator につなぐ（例 firebase:8080）
//   FIREBASE_AUTH_EMULATOR_HOST   あれば Auth Emulator のトークンを受け付ける（署名を確かめない。例 firebase:9099）
//   ALLOWED_ORIGIN                ブラウザから別のオリジンで呼ぶときに許すオリジン（例 http://localhost:5000）

export type Config = {
  port: number;
  projectId: string;
  firestoreEmulatorHost?: string;
  authEmulatorHost?: string;
  allowedOrigin?: string;
};

export function configFrom(env: Record<string, string | undefined>): Config {
  const port = Number(env.PORT ?? '8787');
  if (!Number.isInteger(port) || port <= 0) throw new Error(`PORT が正しくありません：${env.PORT}`);
  const projectId = env.FIREBASE_PROJECT || 'demo-dev-portfolio';
  const config: Config = {
    port,
    projectId,
    firestoreEmulatorHost: env.FIRESTORE_EMULATOR_HOST || undefined,
    authEmulatorHost: env.FIREBASE_AUTH_EMULATOR_HOST || undefined,
    allowedOrigin: env.ALLOWED_ORIGIN || undefined,
  };
  // demo- のプロジェクトは Emulator にしかない。本物に向けて動かすことはない
  if (projectId.startsWith('demo-') && (!config.firestoreEmulatorHost || !config.authEmulatorHost)) {
    throw new Error('demo- のプロジェクトでは FIRESTORE_EMULATOR_HOST と FIREBASE_AUTH_EMULATOR_HOST を指定してください');
  }
  // Emulator のトークン（署名なし）を受け付けるのは Emulator につなぐときだけ
  if (config.authEmulatorHost && !config.firestoreEmulatorHost) {
    throw new Error('FIREBASE_AUTH_EMULATOR_HOST を使うときは FIRESTORE_EMULATOR_HOST も指定してください（本物のデータを署名なしのトークンで読ませないため）');
  }
  return config;
}
