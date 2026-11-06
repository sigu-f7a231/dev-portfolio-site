// src/app.ts
//
// ルート（Hono）。Node（server.ts）と Workers（worker.ts）の両方から使う
//   GET    /healthz                    … 動作確認（コンテナのヘルスチェック・死活の確認）
//   GET    /api/public/:slug           … 公開ページのデータ（ログインいらない）
//   ---- ここから下はログインが要る（Authorization: Bearer <Firebase の ID トークン>）。読み書きできるのは本人のデータだけ ----
//   GET    /api/me/draft               … 編集中のデータ全体と updatedAt
//   PUT    /api/me/draft               … 全体を保存 { data, updatedAt }（updatedAt は読んだときの値。違えば 409）
//   GET    /api/me/profile             … プロフィール（PUT で置き換え）
//   GET    /api/me/skills              … スキル（PUT で置き換え）
//   GET    /api/me/display             … 表示設定（PUT で置き換え）
//   GET    /api/me/projects            … 職務経歴の一覧
//   POST   /api/me/projects            … 1 件足す（id がなければ作る）
//   PUT    /api/me/projects/:id        … 1 件を置き換え
//   DELETE /api/me/projects/:id        … 1 件消す
// 応答はすべて JSON。エラーは {"error": {"code", "message", "details"?}}（前の backend と同じ形）
import { Hono, type Context } from 'hono';
import { cors } from 'hono/cors';
import type { ContentfulStatusCode } from 'hono/utils/http-status';

import type { TokenVerifier } from './auth.ts';
import { ApiError, badRequest } from './errors.ts';
import { logEntry, logRequest, type LogWriter } from './log.ts';
import type { PortfolioService, Section } from './portfolio.ts';

export type AppDeps = {
  service: PortfolioService;
  verifier: TokenVerifier;
  allowedOrigin?: string;
  log?: LogWriter;
};

type Env = { Variables: { uid: string } };

const SECTIONS: Section[] = ['profile', 'skills', 'display'];

async function readJson(c: Context): Promise<unknown> {
  try {
    return await c.req.json();
  } catch {
    throw badRequest('JSON として読めません');
  }
}

export function createApp({ service, verifier, allowedOrigin, log = console.log }: AppDeps) {
  const app = new Hono<Env>();

  // 1 リクエスト 1 行のログ（個人の情報は書かない）
  app.use('*', async (c, next) => {
    const started = Date.now();
    await next();
    logRequest(log, { method: c.req.method, path: c.req.path, status: c.res.status, latencyMs: Date.now() - started });
  });

  // ブラウザから別のオリジン（flutter run の画面など）で呼ぶときだけ
  if (allowedOrigin) {
    app.use('/api/*', cors({ origin: allowedOrigin, allowHeaders: ['Authorization', 'Content-Type'], maxAge: 600 }));
  }

  app.onError((err, c) => {
    if (err instanceof ApiError) {
      return c.json(
        { error: { code: err.code, message: err.message, ...(err.details.length ? { details: err.details } : {}) } },
        err.status as ContentfulStatusCode,
      );
    }
    logEntry(log, 'ERROR', `Unhandled error: ${err instanceof Error ? err.message : String(err)}`, {
      stack_trace: err instanceof Error ? err.stack : undefined,
    });
    return c.json({ error: { code: 'internal', message: 'サーバーでエラーが起きました' } }, 500);
  });

  app.notFound((c) => c.json({ error: { code: 'not_found', message: 'ページがありません' } }, 404));

  app.get('/healthz', (c) => {
    c.header('Cache-Control', 'no-store');
    return c.json({ status: 'ok' });
  });

  app.get('/api/public/:slug', async (c) => {
    const page = await service.getPublicPage(c.req.param('slug'));
    c.header('Cache-Control', 'public, max-age=60'); // 公開ページは CDN で短くキャッシュ
    return c.json(page);
  });

  // ---------------- ここから下はログインが要る ----------------
  app.use('/api/me/*', async (c, next) => {
    const { uid } = await verifier.verifyHeader(c.req.header('Authorization'));
    c.set('uid', uid);
    c.header('Cache-Control', 'no-store'); // 本人のデータはキャッシュさせない
    await next();
  });

  app.get('/api/me/draft', async (c) => c.json(await service.getDraft(c.get('uid'))));

  app.put('/api/me/draft', async (c) => {
    const body = await readJson(c);
    if (typeof body !== 'object' || body === null || !('data' in body) || !('updatedAt' in body)) {
      throw badRequest('{ "data": ..., "updatedAt": 読んだときの値（はじめては null） } の形で送ってください');
    }
    const { data, updatedAt } = body as { data: unknown; updatedAt: unknown };
    if (updatedAt !== null && typeof updatedAt !== 'string') throw badRequest('updatedAt は文字か null です');
    return c.json(await service.saveDraft(c.get('uid'), data, updatedAt));
  });

  for (const section of SECTIONS) {
    app.get(`/api/me/${section}`, async (c) => c.json(await service.getSection(c.get('uid'), section)));
    app.put(`/api/me/${section}`, async (c) =>
      c.json(await service.putSection(c.get('uid'), section, await readJson(c))),
    );
  }

  app.get('/api/me/projects', async (c) => c.json(await service.listProjects(c.get('uid'))));
  app.post('/api/me/projects', async (c) => c.json(await service.addProject(c.get('uid'), await readJson(c)), 201));
  app.put('/api/me/projects/:id', async (c) =>
    c.json(await service.updateProject(c.get('uid'), c.req.param('id'), await readJson(c))),
  );
  app.delete('/api/me/projects/:id', async (c) => {
    await service.deleteProject(c.get('uid'), c.req.param('id'));
    return c.body(null, 204);
  });

  return app;
}
