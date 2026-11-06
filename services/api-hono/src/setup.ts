// src/setup.ts
//
// 設定からアプリを組み立てる（server.ts・worker.ts で共通）
import { createApp } from './app.ts';
import { TokenVerifier } from './auth.ts';
import type { Config } from './config.ts';
import { FirestoreRestStore, type AccessTokenProvider } from './firestore.ts';
import { PortfolioService } from './portfolio.ts';

export function buildApp(config: Config, options: { accessToken?: AccessTokenProvider } = {}) {
  const store = new FirestoreRestStore({
    projectId: config.projectId,
    emulatorHost: config.firestoreEmulatorHost,
    accessToken: options.accessToken,
  });
  return createApp({
    service: new PortfolioService(store),
    verifier: new TokenVerifier({ projectId: config.projectId, emulator: Boolean(config.authEmulatorHost) }),
    allowedOrigin: config.allowedOrigin,
  });
}
