// test/firestore.test.ts … Firestore の REST（偽物の fetch に送った中身を確かめる）
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { ConflictError } from '../src/errors.ts';
import { FirestoreRestStore, metadataServerToken } from '../src/firestore.ts';

type Call = { url: string; init?: RequestInit };

function fakeFetch(respond: (call: Call) => Response) {
  const calls: Call[] = [];
  const fn = (async (url: string | URL | Request, init?: RequestInit) => {
    const call = { url: String(url), init };
    calls.push(call);
    return respond(call);
  }) as typeof fetch;
  return { fn, calls };
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { 'Content-Type': 'application/json' } });

test('Emulator：http://<ホスト>/v1/... に Bearer owner で読む。なければ null', async () => {
  const f = fakeFetch(({ url }) =>
    url.endsWith('/users/a')
      ? json({ fields: { slug: { stringValue: 's' } }, updateTime: '2026-11-06T00:00:00.000001Z' })
      : json({ error: {} }, 404),
  );
  const store = new FirestoreRestStore({ projectId: 'demo-p', emulatorHost: 'firebase:8080', fetchFn: f.fn });
  assert.deepEqual(await store.get('users/a'), { data: { slug: 's' }, updateTime: '2026-11-06T00:00:00.000001Z' });
  assert.equal(await store.get('users/b'), null);
  assert.equal(f.calls[0].url, 'http://firebase:8080/v1/projects/demo-p/databases/(default)/documents/users/a');
  assert.equal((f.calls[0].init?.headers as Record<string, string>).Authorization, 'Bearer owner');
});

test('commit：書く・項目だけ書く・消す、前提（exists / updateTime）を付ける', async () => {
  const f = fakeFetch(() => json({}));
  const store = new FirestoreRestStore({ projectId: 'demo-p', emulatorHost: 'h:1', fetchFn: f.fn });
  await store.commit([
    { path: 'users/a', set: { n: 1 }, precondition: { exists: false } },
    { path: 'users/a/drafts/current', set: { x: 'y' }, mask: ['x'], precondition: { updateTime: 't1' } },
    { path: 'users/a/old', delete: true },
  ]);
  assert.equal(f.calls[0].url, 'http://h:1/v1/projects/demo-p/databases/(default)/documents:commit');
  assert.equal(f.calls[0].init?.method, 'POST');
  const body = JSON.parse(String(f.calls[0].init?.body));
  const name = 'projects/demo-p/databases/(default)/documents';
  assert.deepEqual(body.writes, [
    { update: { name: `${name}/users/a`, fields: { n: { integerValue: '1' } } }, currentDocument: { exists: false } },
    {
      update: { name: `${name}/users/a/drafts/current`, fields: { x: { stringValue: 'y' } } },
      updateMask: { fieldPaths: ['x'] },
      currentDocument: { updateTime: 't1' },
    },
    { delete: `${name}/users/a/old` },
  ]);
});

test('commit の異常系：前提が崩れたら ConflictError、それ以外はエラー', async () => {
  for (const [status, text] of [
    [400, '{"error":{"status":"FAILED_PRECONDITION"}}'],
    [409, '{"error":{"status":"ALREADY_EXISTS"}}'],
    [404, '{"error":{"status":"NOT_FOUND"}}'],
  ] as const) {
    const store = new FirestoreRestStore({ projectId: 'p', emulatorHost: 'h:1', fetchFn: fakeFetch(() => new Response(text, { status })).fn });
    await assert.rejects(store.commit([{ path: 'a/b', set: {} }]), ConflictError);
  }
  const broken = new FirestoreRestStore({ projectId: 'p', emulatorHost: 'h:1', fetchFn: fakeFetch(() => new Response('boom', { status: 500 })).fn });
  await assert.rejects(broken.commit([{ path: 'a/b', set: {} }]), /書けませんでした（500）/);
  await assert.rejects(broken.get('a/b'), /読めませんでした（500）/);
});

test('本物：firestore.googleapis.com に、渡したアクセストークンで', async () => {
  const f = fakeFetch(() => json({ error: {} }, 404));
  const store = new FirestoreRestStore({ projectId: 'real', accessToken: async () => 'tok', fetchFn: f.fn });
  await store.get('x/y');
  assert.equal(f.calls[0].url, 'https://firestore.googleapis.com/v1/projects/real/databases/(default)/documents/x/y');
  assert.equal((f.calls[0].init?.headers as Record<string, string>).Authorization, 'Bearer tok');
});

test('メタデータサーバーのトークン：期限まで使い回す。取れなければエラー', async () => {
  const f = fakeFetch(() => json({ access_token: 'meta', expires_in: 3600 }));
  const token = metadataServerToken(f.fn);
  assert.equal(await token(), 'meta');
  assert.equal(await token(), 'meta');
  assert.equal(f.calls.length, 1);
  assert.equal((f.calls[0].init?.headers as Record<string, string>)['Metadata-Flavor'], 'Google');
  await assert.rejects(metadataServerToken(fakeFetch(() => new Response('', { status: 403 })).fn)(), /403/);
});
