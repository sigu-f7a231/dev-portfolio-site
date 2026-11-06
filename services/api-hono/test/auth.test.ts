// test/auth.test.ts … ID トークンを確かめる（本物：RS256 の署名、Emulator：署名なし）
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { TokenVerifier } from '../src/auth.ts';
import { ApiError } from '../src/errors.ts';
import { PROJECT, claimsFor, unsignedToken } from './helpers.ts';

const NOW = 1_800_000_000;
const b64url = (obj: object) => Buffer.from(JSON.stringify(obj)).toString('base64url');

/** RS256 の鍵を作り、署名したトークンと公開鍵（JWK）を返す */
async function signer(kid = 'key-1') {
  const pair = (await crypto.subtle.generateKey(
    { name: 'RSASSA-PKCS1-v1_5', modulusLength: 2048, publicExponent: new Uint8Array([1, 0, 1]), hash: 'SHA-256' },
    true,
    ['sign', 'verify'],
  )) as CryptoKeyPair;
  const jwk = { ...(await crypto.subtle.exportKey('jwk', pair.publicKey)), kid };
  const sign = async (claims: object, header: object = { alg: 'RS256', kid, typ: 'JWT' }) => {
    const input = `${b64url(header)}.${b64url(claims)}`;
    const sig = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', pair.privateKey, new TextEncoder().encode(input));
    return `${input}.${Buffer.from(sig).toString('base64url')}`;
  };
  return { jwk, sign };
}

async function rejects(p: Promise<unknown>, message: RegExp) {
  await assert.rejects(p, (e: unknown) => e instanceof ApiError && e.status === 401 && message.test(e.message));
}

test('本物：正しく署名されたトークンなら uid を返す。公開鍵は期限まで使い回す', async () => {
  const { jwk, sign } = await signer();
  let fetched = 0;
  const v = new TokenVerifier({
    projectId: PROJECT,
    emulator: false,
    nowSeconds: () => NOW,
    fetchJwks: async () => {
      fetched++;
      return { keys: [jwk], maxAgeSeconds: 600 };
    },
  });
  const token = await sign(claimsFor('user-a', {}, NOW));
  assert.equal((await v.verify(token)).uid, 'user-a');
  assert.equal((await v.verifyHeader(`Bearer ${token}`)).uid, 'user-a');
  assert.equal(fetched, 1);
});

test('本物：異常系（署名が違う・鍵がない・alg が none・署名なし）', async () => {
  const a = await signer('key-1');
  const other = await signer('key-1'); // 同じ kid でも別の鍵
  const v = new TokenVerifier({
    projectId: PROJECT,
    emulator: false,
    nowSeconds: () => NOW,
    fetchJwks: async () => ({ keys: [a.jwk], maxAgeSeconds: 600 }),
  });
  const claims = claimsFor('user-a', {}, NOW);
  await rejects(v.verify(await other.sign(claims)), /署名が正しくありません/);
  await rejects(v.verify(await a.sign(claims, { alg: 'RS256', kid: 'unknown' })), /鍵が見つかりません/);
  await rejects(v.verify(unsignedToken(claims)), /署名の方式/);
});

test('Emulator：署名なしのトークンを受け付ける（中身は確かめる）', async () => {
  const v = new TokenVerifier({ projectId: PROJECT, emulator: true, nowSeconds: () => NOW });
  assert.equal((await v.verify(unsignedToken(claimsFor('emu-user', {}, NOW)))).uid, 'emu-user');
});

test('中身の異常系：ほかのプロジェクト・発行元・期限切れ・未来の発行・利用者なし', async () => {
  const v = new TokenVerifier({ projectId: PROJECT, emulator: true, nowSeconds: () => NOW });
  const t = (o: Record<string, unknown>) => v.verify(unsignedToken(claimsFor('u', o, NOW)));
  await rejects(t({ aud: 'other-project' }), /ほかのプロジェクト/);
  await rejects(t({ iss: 'https://evil.example.com' }), /発行元/);
  await rejects(t({ exp: NOW - 120 }), /期限が切れました/);
  await rejects(t({ iat: NOW + 3600 }), /発行時刻/);
  await rejects(t({ auth_time: NOW + 3600 }), /ログインの時刻/);
  await rejects(t({ sub: '' }), /利用者が分かりません/);
  await rejects(t({ sub: 'x'.repeat(129) }), /利用者が分かりません/);
  // 時計のずれ（60 秒）までは許す
  assert.equal((await t({ exp: NOW - 30 })).uid, 'u');
});

test('形の異常系：ヘッダーなし・Bearer でない・3 つに分かれていない・読めない', async () => {
  const v = new TokenVerifier({ projectId: PROJECT, emulator: true, nowSeconds: () => NOW });
  await rejects(v.verifyHeader(undefined), /ログインしてください/);
  await rejects(v.verifyHeader('Basic abc'), /ログインしてください/);
  await rejects(v.verify('a.b'), /形が正しくありません/);
  await rejects(v.verify('@@@.###.'), /読めません/);
});
