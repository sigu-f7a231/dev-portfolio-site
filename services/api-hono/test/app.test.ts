// test/app.test.ts … ルート（Hono）。app.request でリクエストを送る（サーバーは起動しない）
// Firestore はメモリ上の偽物、トークンは Auth Emulator と同じ署名のないもの
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createApp } from '../src/app.ts';
import { TokenVerifier } from '../src/auth.ts';
import { PortfolioService } from '../src/portfolio.ts';
import { MemoryStore, PROJECT, claimsFor, unsignedToken, workProject } from './helpers.ts';

function setup({ allowedOrigin, store = new MemoryStore() }: { allowedOrigin?: string; store?: MemoryStore } = {}) {
  const logs: string[] = [];
  const app = createApp({
    service: new PortfolioService(store),
    verifier: new TokenVerifier({ projectId: PROJECT, emulator: true }),
    allowedOrigin,
    log: (line) => logs.push(line),
  });
  const as = (uid: string) => ({ Authorization: `Bearer ${unsignedToken(claimsFor(uid))}` });
  const send = (path: string, init: { method?: string; uid?: string; body?: unknown; headers?: Record<string, string> } = {}) =>
    app.request(path, {
      method: init.method ?? 'GET',
      headers: {
        ...(init.uid ? as(init.uid) : {}),
        ...(init.body !== undefined ? { 'Content-Type': 'application/json' } : {}),
        ...init.headers,
      },
      body: init.body === undefined ? undefined : typeof init.body === 'string' ? init.body : JSON.stringify(init.body),
    });
  return { app, store, logs, send };
}

test('/healthz：動いていれば 200、キャッシュさせない', async () => {
  const { send } = setup();
  const res = await send('/healthz');
  assert.equal(res.status, 200);
  assert.deepEqual(await res.json(), { status: 'ok' });
  assert.equal(res.headers.get('cache-control'), 'no-store');
});

test('ログインが要る：トークンなし・壊れたトークン・ほかのプロジェクトは 401（同じ形のエラー）', async () => {
  const { send } = setup();
  const cases: Record<string, string>[] = [
    {},
    { Authorization: 'Bearer broken' },
    { Authorization: `Bearer ${unsignedToken(claimsFor('a', { aud: 'other' }))}` },
  ];
  for (const headers of cases) {
    const res = await send('/api/me/profile', { headers });
    assert.equal(res.status, 401);
    const body = (await res.json()) as { error: { code: string; message: string } };
    assert.equal(body.error.code, 'unauthorized');
    assert.ok(body.error.message.length > 0);
  }
});

test('本人のデータだけ：A が書いたものは A にだけ見え、B には見えない', async () => {
  const { send, store } = setup();
  const put = await send('/api/me/profile', { method: 'PUT', uid: 'user-a', body: { home: { name: 'A さん' } } });
  assert.equal(put.status, 200);
  assert.deepEqual(await put.json(), { home: { name: 'A さん' } });
  assert.equal(put.headers.get('cache-control'), 'no-store');

  assert.deepEqual(await (await send('/api/me/profile', { uid: 'user-a' })).json(), { home: { name: 'A さん' } });
  assert.deepEqual(await (await send('/api/me/profile', { uid: 'user-b' })).json(), {});
  assert.deepEqual([...store.docs.keys()].sort(), ['users/user-a', 'users/user-a/drafts/current']);
});

test('スキル・表示設定も同じく読み書きできる', async () => {
  const { send } = setup();
  for (const [section, value] of [
    ['skills', { recentTech: { skills: ['Dart'] } }],
    ['display', { theme: 'dark', projects: { view: 'collection' } }],
  ] as const) {
    assert.equal((await send(`/api/me/${section}`, { method: 'PUT', uid: 'a', body: value })).status, 200);
    assert.deepEqual(await (await send(`/api/me/${section}`, { uid: 'a' })).json(), value);
  }
});

test('編集データ全体：読む → updatedAt を付けて保存 → 古い updatedAt なら 409', async () => {
  const { send } = setup();
  const first = (await (await send('/api/me/draft', { uid: 'a' })).json()) as { updatedAt: string | null; data: object };
  assert.equal(first.updatedAt, null);
  const saved = await send('/api/me/draft', { method: 'PUT', uid: 'a', body: { data: first.data, updatedAt: null } });
  assert.equal(saved.status, 200);
  const { updatedAt } = (await saved.json()) as { updatedAt: string };
  const again = await send('/api/me/draft', { method: 'PUT', uid: 'a', body: { data: first.data, updatedAt: null } });
  assert.equal(again.status, 409);
  assert.equal(((await again.json()) as { error: { code: string } }).error.code, 'conflict');
  const ok = await send('/api/me/draft', { method: 'PUT', uid: 'a', body: { data: first.data, updatedAt } });
  assert.equal(ok.status, 200);
});

test('編集データ全体の異常系：形が違う・updatedAt がない・JSON でない', async () => {
  const { send } = setup();
  const invalid = await send('/api/me/draft', { method: 'PUT', uid: 'a', body: { data: { extra: 1 }, updatedAt: null } });
  assert.equal(invalid.status, 400);
  const body = (await invalid.json()) as { error: { code: string; details: string[] } };
  assert.equal(body.error.code, 'invalid_request');
  assert.ok(body.error.details.some((d) => d.includes('data.extra')));
  assert.equal((await send('/api/me/draft', { method: 'PUT', uid: 'a', body: { data: {} } })).status, 400);
  assert.equal((await send('/api/me/draft', { method: 'PUT', uid: 'a', body: { data: {}, updatedAt: 1 } })).status, 400);
  assert.equal((await send('/api/me/profile', { method: 'PUT', uid: 'a', body: '{ not json' })).status, 400);
});

test('職務経歴：一覧・足す（201）・置き換え・消す（204）・ないものは 404', async () => {
  const { send } = setup();
  const added = await send('/api/me/projects', { method: 'POST', uid: 'a', body: workProject });
  assert.equal(added.status, 201);
  const put = await send(`/api/me/projects/${workProject.id}`, { method: 'PUT', uid: 'a', body: { ...workProject, title: '変えた' } });
  assert.equal(((await put.json()) as { title: string }).title, '変えた');
  const list = (await (await send('/api/me/projects', { uid: 'a' })).json()) as { id: string }[];
  assert.deepEqual(list.map((p) => p.id), [workProject.id]);
  assert.equal((await send(`/api/me/projects/${workProject.id}`, { method: 'DELETE', uid: 'b' })).status, 404, 'ほかの人の案件は消せない');
  assert.equal((await send(`/api/me/projects/${workProject.id}`, { method: 'DELETE', uid: 'a' })).status, 204);
  assert.equal((await send(`/api/me/projects/${workProject.id}`, { method: 'DELETE', uid: 'a' })).status, 404);
});

test('公開ページ：ログインなしで読める（短くキャッシュ）。ないものは 404', async () => {
  const { send, store } = setup();
  store.put('publicPages/sample', { data: { profile: { home: { name: '公開' } } }, version: 1, publishedAt: 'x' });
  const res = await send('/api/public/sample');
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('cache-control'), 'public, max-age=60');
  assert.equal((await send('/api/public/none')).status, 404);
});

test('ない URL は 404 の JSON', async () => {
  const { send } = setup();
  const res = await send('/api/unknown');
  assert.equal(res.status, 404);
  assert.deepEqual(await res.json(), { error: { code: 'not_found', message: 'ページがありません' } });
});

test('思わぬエラーは 500（中身は出さない）。ログは ERROR', async () => {
  const store = new MemoryStore();
  store.get = async () => {
    throw new Error('Firestore が落ちた');
  };
  const { send, logs } = setup({ store });
  const res = await send('/api/me/profile', { uid: 'a' });
  assert.equal(res.status, 500);
  assert.deepEqual(await res.json(), { error: { code: 'internal', message: 'サーバーでエラーが起きました' } });
  assert.ok(logs.some((l) => JSON.parse(l).severity === 'ERROR' && l.includes('Firestore が落ちた')));
});

test('ログ：1 リクエスト 1 行の JSON（severity・httpRequest）。uid やプロフィールの中身は書かない', async () => {
  const { send, logs } = setup();
  await send('/api/me/profile', { method: 'PUT', uid: 'secret-uid', body: { home: { name: '秘密の名前' } } });
  await send('/api/me/profile');
  const lines = logs.map((l) => JSON.parse(l));
  assert.equal(lines.length, 2);
  assert.equal(lines[0].severity, 'INFO');
  assert.equal(lines[0].httpRequest.status, 200);
  assert.equal(lines[1].severity, 'WARNING');
  assert.ok(!logs.join('\n').includes('secret-uid'));
  assert.ok(!logs.join('\n').includes('秘密の名前'));
});

test('CORS：ALLOWED_ORIGIN を指定したときだけ、そのオリジンを許す', async () => {
  const withCors = setup({ allowedOrigin: 'http://localhost:5000' });
  const pre = await withCors.send('/api/me/profile', {
    method: 'OPTIONS',
    headers: { Origin: 'http://localhost:5000', 'Access-Control-Request-Method': 'PUT' },
  });
  assert.equal(pre.headers.get('access-control-allow-origin'), 'http://localhost:5000');
  const without = setup();
  const res = await without.send('/api/public/none', { headers: { Origin: 'http://localhost:5000' } });
  assert.equal(res.headers.get('access-control-allow-origin'), null);
});

test('本人の情報・名前・公開・公開を止める・退会のルート', async () => {
  const { send, store } = setup();
  assert.deepEqual(await (await send('/api/me', { uid: 'a' })).json(), {
    slug: null,
    latestVersion: 0,
    publishedVersion: null,
    updatedAt: null,
  });
  assert.equal((await send('/api/me/slug', { method: 'PUT', uid: 'a', body: { slug: 'Bad Name' } })).status, 400);
  assert.equal((await send('/api/me/slug', { method: 'PUT', uid: 'a', body: { slug: 'taro' } })).status, 200);
  assert.equal((await send('/api/me/slug', { method: 'PUT', uid: 'b', body: { slug: 'taro' } })).status, 409);

  assert.equal((await send('/api/me/publish', { method: 'POST', uid: 'a' })).status, 409, 'まだ保存していない');
  await send('/api/me/profile', {
    method: 'PUT',
    uid: 'a',
    body: { home: { name: 'A', role: 'R', tagline: 'T' }, about: { intro: 'I' }, sheet: { furigana: 'ひみつ' } },
  });
  const published = await send('/api/me/publish', { method: 'POST', uid: 'a' });
  assert.equal(published.status, 200);
  assert.equal(((await published.json()) as { publishedVersion: number }).publishedVersion, 1);
  const page = (await (await send('/api/public/taro')).json()) as { data: { profile: Record<string, unknown> } };
  assert.equal(page.data.profile.sheet, undefined);

  assert.equal(((await (await send('/api/me/publish', { method: 'DELETE', uid: 'a' })).json()) as { publishedVersion: null }).publishedVersion, null);
  assert.equal((await send('/api/public/taro')).status, 404);

  assert.equal((await send('/api/me', { method: 'DELETE', uid: 'a' })).status, 204);
  assert.equal([...store.docs.keys()].some((k) => k.includes('users/a')), false);
  assert.equal((await send('/api/me', { method: 'DELETE' })).status, 401);
});
