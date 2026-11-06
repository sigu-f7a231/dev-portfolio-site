// src/auth.ts
//
// Firebase の ID トークン（Authorization: Bearer <トークン>）を確かめ、本人の uid を返す
// - 本物：Google の公開鍵（JWK）で RS256 の署名を確かめる（Web Crypto。Node・Workers のどちらでも動く。Admin SDK は使わない）
// - Emulator（FIREBASE_AUTH_EMULATOR_HOST があるとき）：Auth Emulator のトークンには署名がないので、署名は確かめない
// - どちらも、宛先（aud）・発行元（iss）・期限（exp）・発行時刻（iat）・本人（sub）を確かめる
// https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
import { unauthorized } from './errors.ts';

export const GOOGLE_JWKS_URL =
  'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

/** 時計のずれとして許す秒数 */
const CLOCK_SKEW_SECONDS = 60;

type JwtHeader = { alg?: string; kid?: string; typ?: string };
type JwtPayload = {
  aud?: string;
  iss?: string;
  sub?: string;
  exp?: number;
  iat?: number;
  auth_time?: number;
  user_id?: string;
};

export type VerifiedToken = { uid: string; claims: JwtPayload };

export type TokenVerifierOptions = {
  projectId: string;
  /** true なら署名を確かめない（Auth Emulator のとき） */
  emulator: boolean;
  /** 公開鍵の取得（テストで差し替える） */
  fetchJwks?: () => Promise<{ keys: (JsonWebKey & { kid?: string })[]; maxAgeSeconds: number }>;
  /** 今の時刻（秒。テストで差し替える） */
  nowSeconds?: () => number;
};

function base64UrlDecode(part: string): Uint8Array<ArrayBuffer> {
  const base64 = part.replace(/-/g, '+').replace(/_/g, '/').padEnd(Math.ceil(part.length / 4) * 4, '=');
  const binary = atob(base64);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

function decodeJson<T>(part: string): T {
  return JSON.parse(new TextDecoder().decode(base64UrlDecode(part))) as T;
}

/** Google の公開鍵を取る（Cache-Control の max-age のあいだは使い回す） */
async function fetchGoogleJwks() {
  const res = await fetch(GOOGLE_JWKS_URL);
  if (!res.ok) throw new Error(`公開鍵を取れませんでした（${res.status}）`);
  const maxAge = /max-age=(\d+)/.exec(res.headers.get('cache-control') ?? '')?.[1];
  return { keys: ((await res.json()) as { keys: (JsonWebKey & { kid?: string })[] }).keys, maxAgeSeconds: Number(maxAge ?? 3600) };
}

export class TokenVerifier {
  private readonly options: Required<TokenVerifierOptions>;
  private cache?: { keys: Map<string, CryptoKey>; expiresAt: number };

  constructor(options: TokenVerifierOptions) {
    this.options = {
      fetchJwks: fetchGoogleJwks,
      nowSeconds: () => Math.floor(Date.now() / 1000),
      ...options,
    };
  }

  /** Authorization ヘッダーの値から確かめる。なければ・正しくなければ 401 の ApiError */
  async verifyHeader(authorization: string | undefined | null): Promise<VerifiedToken> {
    const match = /^Bearer\s+(.+)$/i.exec(authorization ?? '');
    if (!match) throw unauthorized();
    return this.verify(match[1].trim());
  }

  async verify(token: string): Promise<VerifiedToken> {
    const parts = token.split('.');
    if (parts.length !== 3) throw unauthorized('トークンの形が正しくありません');
    let header: JwtHeader;
    let payload: JwtPayload;
    try {
      header = decodeJson<JwtHeader>(parts[0]);
      payload = decodeJson<JwtPayload>(parts[1]);
    } catch {
      throw unauthorized('トークンを読めません');
    }

    const { projectId, emulator, nowSeconds } = this.options;
    const now = nowSeconds();
    if (payload.aud !== projectId) throw unauthorized('ほかのプロジェクトのトークンです');
    if (payload.iss !== `https://securetoken.google.com/${projectId}`) throw unauthorized('発行元が正しくありません');
    if (typeof payload.sub !== 'string' || payload.sub.length === 0 || payload.sub.length > 128) {
      throw unauthorized('利用者が分かりません');
    }
    if (typeof payload.exp !== 'number' || payload.exp + CLOCK_SKEW_SECONDS < now) {
      throw unauthorized('ログインの期限が切れました。もう一度ログインしてください');
    }
    if (typeof payload.iat !== 'number' || payload.iat - CLOCK_SKEW_SECONDS > now) {
      throw unauthorized('トークンの発行時刻が正しくありません');
    }
    if (typeof payload.auth_time === 'number' && payload.auth_time - CLOCK_SKEW_SECONDS > now) {
      throw unauthorized('ログインの時刻が正しくありません');
    }

    if (!emulator) {
      if (header.alg !== 'RS256' || !header.kid) throw unauthorized('署名の方式が正しくありません');
      const key = (await this.keys()).get(header.kid);
      if (!key) throw unauthorized('署名の鍵が見つかりません');
      const ok = await crypto.subtle.verify(
        'RSASSA-PKCS1-v1_5',
        key,
        base64UrlDecode(parts[2]),
        new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
      );
      if (!ok) throw unauthorized('署名が正しくありません');
    }

    return { uid: payload.sub, claims: payload };
  }

  private async keys(): Promise<Map<string, CryptoKey>> {
    const now = this.options.nowSeconds();
    if (this.cache && this.cache.expiresAt > now) return this.cache.keys;
    const { keys, maxAgeSeconds } = await this.options.fetchJwks();
    const imported = new Map<string, CryptoKey>();
    for (const jwk of keys) {
      if (!jwk.kid) continue;
      imported.set(
        jwk.kid,
        await crypto.subtle.importKey('jwk', jwk, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['verify']),
      );
    }
    this.cache = { keys: imported, expiresAt: now + maxAgeSeconds };
    return imported;
  }
}
