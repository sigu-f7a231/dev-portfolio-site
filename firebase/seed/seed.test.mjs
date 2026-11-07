// firebase/seed/seed.test.mjs
//
// seed.mjs のテスト（Node の標準のテスト。パッケージはいらない）
//   node --test firebase/seed/seed.test.mjs
// 偽物の Emulator（Auth・Firestore の REST を受けるだけの HTTP サーバー）を立て、送った中身を確かめる
import assert from 'node:assert/strict';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

import { publicDataOf, seed, setLog, toFields, toValue } from './seed.mjs';

setLog(() => {}); // 進み具合は表示しない

const sample = JSON.parse(await readFile(new URL('./sample.json', import.meta.url), 'utf8'));

/** 偽物の Emulator。emailExists なら signUp で EMAIL_EXISTS を返す。lists はコレクション → 返す文書の並び */
async function fakeEmulator({ emailExists = false, failWrite = false, lists = {} } = {}) {
  const requests = [];
  const server = createServer(async (req, res) => {
    let body = '';
    for await (const chunk of req) body += chunk;
    requests.push({ method: req.method, url: req.url, headers: req.headers, body: body ? JSON.parse(body) : null });
    const send = (status, json) => {
      res.writeHead(status, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify(json));
    };
    if (req.url.includes('accounts:signUp')) {
      return emailExists ? send(400, { error: { message: 'EMAIL_EXISTS' } }) : send(200, { localId: 'uid-new' });
    }
    if (req.url.includes('accounts:signInWithPassword')) return send(200, { localId: 'uid-existing' });
    if (req.url.includes('/documents/') && req.method === 'GET') {
      const collection = decodeURIComponent(req.url.split('/documents/')[1].split('?')[0]);
      return send(200, lists[collection] ? { documents: lists[collection] } : {});
    }
    if (req.url.includes('/documents/')) return failWrite ? send(403, { error: 'denied' }) : send(200, {});
    return send(404, {});
  });
  await new Promise((resolve) => server.listen(0, '127.0.0.1', resolve));
  const host = `127.0.0.1:${server.address().port}`;
  return { host, requests, close: () => new Promise((resolve) => server.close(resolve)) };
}

test('toValue：Firestore の REST の値にする', () => {
  assert.deepEqual(toValue('a'), { stringValue: 'a' });
  assert.deepEqual(toValue(1), { integerValue: '1' });
  assert.deepEqual(toValue(1.5), { doubleValue: 1.5 });
  assert.deepEqual(toValue(true), { booleanValue: true });
  assert.deepEqual(toValue(null), { nullValue: null });
  assert.deepEqual(toValue(new Date('2026-11-06T00:00:00Z')), { timestampValue: '2026-11-06T00:00:00.000Z' });
  assert.deepEqual(toValue(['x']), { arrayValue: { values: [{ stringValue: 'x' }] } });
  assert.deepEqual(toValue([]), { arrayValue: { values: [] } });
  assert.deepEqual(toFields({ a: { b: 1 } }), { a: { mapValue: { fields: { b: { integerValue: '1' } } } } });
});

test('publicDataOf：スキルシートだけの項目（sheet）と、隠したプロジェクトを外す', () => {
  const data = { ...sample.data, display: { projects: { hidden: ['p_sample_private_1'] } } };
  const pub = publicDataOf(data);
  assert.equal(pub.profile.sheet, undefined);
  assert.equal(pub.profile.home.name, 'サンプル 太郎');
  assert.deepEqual(pub.projects.map((p) => p.id), ['p_sample_work_1']);
  assert.ok(data.profile.sheet, '元のデータは変えない');
});

test('サンプルは架空のもの（実在しそうな個人の情報を入れていない）', () => {
  assert.match(sample.user.email, /@example\.com$/);
  assert.deepEqual(Object.keys(sample.data.profile.sheet).sort(), ['furigana', 'station']);
  for (const key of ['birthday', 'gender', 'nationality', 'spouse', 'education']) {
    assert.equal(sample.data.profile.sheet[key], undefined, key);
  }
});

test('seed：利用者を作り、data-model の 5 つの文書を Emulator の管理者として書く', async () => {
  const emu = await fakeEmulator();
  try {
    const now = new Date('2026-11-06T00:00:00Z');
    const paths = await seed({ authHost: emu.host, firestoreHost: emu.host, project: 'demo-test', sample, now });
    assert.deepEqual(paths, [
      'users/uid-new',
      'users/uid-new/drafts/current',
      'users/uid-new/versions/1',
      'slugs/sample',
      'publicPages/sample',
    ]);
    const writes = emu.requests.filter((r) => r.url.includes('/documents/') && r.method !== 'GET');
    assert.equal(writes.length, 5);
    for (const w of writes) {
      assert.equal(w.method, 'PATCH');
      assert.equal(w.headers.authorization, 'Bearer owner');
      assert.ok(w.url.startsWith('/v1/projects/demo-test/databases/(default)/documents/'), w.url);
    }
    const page = writes.find((w) => w.url.endsWith('publicPages/sample')).body.fields.data.mapValue.fields;
    assert.equal(page.profile.mapValue.fields.sheet, undefined, '公開ページに sheet を入れない');
    const draft = writes.find((w) => w.url.endsWith('drafts/current')).body.fields.data.mapValue.fields;
    assert.ok(draft.profile.mapValue.fields.sheet, '本人の編集中のデータには sheet がある');
    assert.deepEqual(draft.schemaVersion, { integerValue: '1' });
  } finally {
    await emu.close();
  }
});

test('seed：前に増えた版・ほかの名前（slugs と publicPages）は消す。ほかの人の名前は消さない', async () => {
  const base = 'projects/demo-test/databases/(default)/documents';
  const uid = (v) => ({ uid: { stringValue: v } });
  const emu = await fakeEmulator({
    lists: {
      'users/uid-new/versions': [{ name: `${base}/users/uid-new/versions/1` }, { name: `${base}/users/uid-new/versions/2` }],
      slugs: [
        { name: `${base}/slugs/sample`, fields: uid('uid-new') },
        { name: `${base}/slugs/sample-2`, fields: uid('uid-new') },
        { name: `${base}/slugs/someone`, fields: uid('uid-other') },
      ],
    },
  });
  try {
    await seed({ authHost: emu.host, firestoreHost: emu.host, project: 'demo-test', sample });
    const deleted = emu.requests.filter((r) => r.method === 'DELETE').map((r) => decodeURIComponent(r.url).split('/documents/')[1]);
    assert.deepEqual(deleted, ['users/uid-new/versions/2', 'slugs/sample-2', 'publicPages/sample-2']);
    for (const r of emu.requests.filter((r) => r.method === 'DELETE' || r.method === 'GET')) {
      if (r.url.includes('/documents/')) assert.equal(r.headers.authorization, 'Bearer owner');
    }
  } finally {
    await emu.close();
  }
});

test('seed：もう利用者がいれば、ログインしてその uid を使う（何度実行してもよい）', async () => {
  const emu = await fakeEmulator({ emailExists: true });
  try {
    const paths = await seed({ authHost: emu.host, firestoreHost: emu.host, project: 'demo-test', sample });
    assert.equal(paths[0], 'users/uid-existing');
  } finally {
    await emu.close();
  }
});

test('seed：異常系：つなぎ先がない・書き込みに失敗したらエラー', async () => {
  await assert.rejects(seed({ authHost: undefined, firestoreHost: 'x', project: 'p', sample }), /FIREBASE_AUTH_EMULATOR_HOST/);
  const emu = await fakeEmulator({ failWrite: true });
  try {
    await assert.rejects(seed({ authHost: emu.host, firestoreHost: emu.host, project: 'p', sample }), /書けませんでした（403）/);
  } finally {
    await emu.close();
  }
});
