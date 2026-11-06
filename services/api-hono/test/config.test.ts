// test/config.test.ts … 環境変数から設定を作る
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { configFrom } from '../src/config.ts';

const emulator = { FIRESTORE_EMULATOR_HOST: 'firebase:8080', FIREBASE_AUTH_EMULATOR_HOST: 'firebase:9099' };

test('既定：ポート 8787・プロジェクト demo-dev-portfolio', () => {
  const c = configFrom(emulator);
  assert.equal(c.port, 8787);
  assert.equal(c.projectId, 'demo-dev-portfolio');
  assert.equal(c.firestoreEmulatorHost, 'firebase:8080');
  assert.equal(c.allowedOrigin, undefined);
});

test('指定したものを使う。空の文字は指定なし', () => {
  const c = configFrom({ ...emulator, PORT: '9000', ALLOWED_ORIGIN: 'http://localhost:5000', FIREBASE_PROJECT: '' });
  assert.equal(c.port, 9000);
  assert.equal(c.allowedOrigin, 'http://localhost:5000');
  assert.equal(c.projectId, 'demo-dev-portfolio');
});

test('本物のプロジェクトなら Emulator なしでよい', () => {
  const c = configFrom({ FIREBASE_PROJECT: 'my-real-project' });
  assert.equal(c.firestoreEmulatorHost, undefined);
  assert.equal(c.authEmulatorHost, undefined);
});

test('異常系：ポートの誤り・demo- なのに Emulator なし・Auth だけ Emulator', () => {
  assert.throws(() => configFrom({ ...emulator, PORT: 'abc' }), /PORT/);
  assert.throws(() => configFrom({}), /demo-/);
  assert.throws(
    () => configFrom({ FIREBASE_PROJECT: 'my-real-project', FIREBASE_AUTH_EMULATOR_HOST: 'x:9099' }),
    /FIRESTORE_EMULATOR_HOST/,
  );
});
