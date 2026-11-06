// test/emulator.test.ts … Firebase Emulator の上でのテスト
// - Auth Emulator が発行したトークンで、API が本人のデータだけを読み書きすること
// - Firestore のセキュリティルール（firebase/firestore.rules）が、画面からの直接の読み書きを断ること
// Emulator を起動してから（リポジトリの直下で docker compose up -d firebase）：
//   FIRESTORE_EMULATOR_HOST=localhost:8080 FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 npm run test:emulator
// 2 つの環境変数がないときは、何もせずに飛ばす（npm test でも動くが、ふだんは飛ばされる）
// 作った利用者と文書は、最後に消す（seed のサンプルには触らない）
import assert from 'node:assert/strict';
import { after, before, describe, test } from 'node:test';

import { configFrom } from '../src/config.ts';
import { buildApp } from '../src/setup.ts';

const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const project = process.env.FIREBASE_PROJECT || 'demo-dev-portfolio';
const skip = !firestoreHost || !authHost ? 'FIRESTORE_EMULATOR_HOST と FIREBASE_AUTH_EMULATOR_HOST がない（Emulator を使うテストを飛ばす）' : false;

const docsUrl = () => `http://${firestoreHost}/v1/projects/${project}/databases/(default)/documents`;

type User = { uid: string; idToken: string; email: string };

async function signUp(): Promise<User> {
  const email = `test-${crypto.randomUUID()}@example.com`;
  const res = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=demo`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'test-password', returnSecureToken: true }),
  });
  assert.equal(res.status, 200, await res.clone().text());
  const json = (await res.json()) as { localId: string; idToken: string };
  return { uid: json.localId, idToken: json.idToken, email };
}

describe('Firebase Emulator の上で', { skip }, () => {
  let a: User;
  let b: User;
  let app: ReturnType<typeof buildApp>;

  before(async () => {
    app = buildApp(configFrom({ ...process.env, FIREBASE_PROJECT: project }));
    [a, b] = await Promise.all([signUp(), signUp()]);
  });

  after(async () => {
    if (!a || !b) return;
    for (const u of [a, b]) {
      for (const path of [`users/${u.uid}/drafts/current`, `users/${u.uid}`]) {
        await fetch(`${docsUrl()}/${path}`, { method: 'DELETE', headers: { Authorization: 'Bearer owner' } });
      }
      await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:delete?key=demo`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${u.idToken}` },
        body: JSON.stringify({ idToken: u.idToken }),
      });
    }
  });

  const call = (user: User | undefined, path: string, method = 'GET', body?: unknown) =>
    app.request(path, {
      method,
      headers: {
        ...(user ? { Authorization: `Bearer ${user.idToken}` } : {}),
        ...(body !== undefined ? { 'Content-Type': 'application/json' } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    });

  test('API：Auth Emulator のトークンで、本人のデータだけを読み書きする', async () => {
    const put = await call(a, '/api/me/profile', 'PUT', { home: { name: 'A さん' } });
    assert.equal(put.status, 200, await put.clone().text());
    assert.deepEqual(await (await call(a, '/api/me/profile')).json(), { home: { name: 'A さん' } });
    assert.deepEqual(await (await call(b, '/api/me/profile')).json(), {}, 'B には A のデータが見えない');

    const added = await call(a, '/api/me/projects', 'POST', { kind: 'work', title: 'エミュレーターの案件' });
    assert.equal(added.status, 201);
    assert.equal(((await (await call(b, '/api/me/projects')).json()) as unknown[]).length, 0);

    // Firestore には A の文書だけがある（管理者として確かめる）
    const owner = { headers: { Authorization: 'Bearer owner' } };
    assert.equal((await fetch(`${docsUrl()}/users/${a.uid}/drafts/current`, owner)).status, 200);
    assert.equal((await fetch(`${docsUrl()}/users/${b.uid}/drafts/current`, owner)).status, 404);
  });

  test('API：トークンがなければ 401', async () => {
    assert.equal((await call(undefined, '/api/me/profile')).status, 401);
  });

  test('セキュリティルール：ログインした本人でも、画面から直接は読めない・書けない', async () => {
    const asA = { Authorization: `Bearer ${a.idToken}`, 'Content-Type': 'application/json' };
    const read = await fetch(`${docsUrl()}/users/${a.uid}/drafts/current`, { headers: asA });
    assert.equal(read.status, 403, await read.clone().text());
    const write = await fetch(`${docsUrl()}/users/${a.uid}`, {
      method: 'PATCH',
      headers: asA,
      body: JSON.stringify({ fields: { slug: { stringValue: 'hack' } } }),
    });
    assert.equal(write.status, 403);
  });

  test('セキュリティルール：ログインしていなければ、公開ページも含めて直接は読めない', async () => {
    for (const path of [`users/${a.uid}`, 'publicPages/sample']) {
      assert.equal((await fetch(`${docsUrl()}/${path}`)).status, 403, path);
    }
  });
});
