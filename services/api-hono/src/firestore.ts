// src/firestore.ts
//
// Firestore の読み書き（REST。Admin SDK を使わないので Node・Workers のどちらでも動く）
// - DocStore：ここだけを通して読み書きする（portfolio.ts が使う。テストではメモリ上の偽物に差し替える）
// - FirestoreRestStore：本物の REST の実装
//   Emulator：http://<FIRESTORE_EMULATOR_HOST>/v1/...、Authorization: Bearer owner（Emulator の管理者。セキュリティルールを通らない）
//   本物  ：https://firestore.googleapis.com/v1/...、サービスアカウントのアクセストークン（Cloud Run のメタデータサーバーから）
// https://firebase.google.com/docs/firestore/reference/rest
import { ConflictError } from './errors.ts';
import { fromFields, toFields, type Fields } from './values.ts';

export type StoredDoc = { data: Record<string, unknown>; updateTime: string };

/** 書き込みの前提（崩れていたら ConflictError） */
export type Precondition = { exists: boolean } | { updateTime: string };

export type Write =
  | {
      path: string;
      set: Record<string, unknown>;
      /** 指定した項目だけを書く（ほかの項目は残す）。なければ文書を丸ごと置き換える */
      mask?: string[];
      precondition?: Precondition;
    }
  | { path: string; delete: true; precondition?: Precondition };

export interface DocStore {
  /** 文書を読む。なければ null */
  get(path: string): Promise<StoredDoc | null>;
  /** まとめて書く（全部書けるか、どれも書かないか）。前提が崩れていたら ConflictError */
  commit(writes: Write[]): Promise<void>;
}

export type AccessTokenProvider = () => Promise<string>;

/** Cloud Run などのメタデータサーバーからアクセストークンを取る（期限の 1 分前まで使い回す） */
export function metadataServerToken(fetchFn: typeof fetch = fetch): AccessTokenProvider {
  let cached: { token: string; expiresAt: number } | undefined;
  return async () => {
    if (cached && cached.expiresAt > Date.now() + 60_000) return cached.token;
    const res = await fetchFn(
      'http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token',
      { headers: { 'Metadata-Flavor': 'Google' } },
    );
    if (!res.ok) throw new Error(`アクセストークンを取れませんでした（${res.status}）`);
    const json = (await res.json()) as { access_token: string; expires_in: number };
    cached = { token: json.access_token, expiresAt: Date.now() + json.expires_in * 1000 };
    return cached.token;
  };
}

export type FirestoreRestOptions = {
  projectId: string;
  /** あれば Emulator（例 firebase:8080） */
  emulatorHost?: string;
  /** 本物のときのアクセストークン（既定はメタデータサーバー） */
  accessToken?: AccessTokenProvider;
  fetchFn?: typeof fetch;
};

export class FirestoreRestStore implements DocStore {
  private readonly base: string;
  private readonly documentsName: string;
  private readonly token: AccessTokenProvider;
  private readonly fetchFn: typeof fetch;

  constructor(options: FirestoreRestOptions) {
    const origin = options.emulatorHost ? `http://${options.emulatorHost}` : 'https://firestore.googleapis.com';
    this.documentsName = `projects/${options.projectId}/databases/(default)/documents`;
    this.base = `${origin}/v1/${this.documentsName}`;
    this.fetchFn = options.fetchFn ?? fetch;
    this.token = options.emulatorHost ? async () => 'owner' : (options.accessToken ?? metadataServerToken(this.fetchFn));
  }

  private async headers() {
    return { Authorization: `Bearer ${await this.token()}`, 'Content-Type': 'application/json' };
  }

  async get(path: string): Promise<StoredDoc | null> {
    const res = await this.fetchFn(`${this.base}/${path}`, { headers: await this.headers() });
    if (res.status === 404) return null;
    if (!res.ok) throw new Error(`Firestore から読めませんでした（${res.status}）：${await res.text()}`);
    const doc = (await res.json()) as { fields?: Fields; updateTime: string };
    return { data: fromFields(doc.fields ?? {}), updateTime: doc.updateTime };
  }

  async commit(writes: Write[]): Promise<void> {
    const body = {
      writes: writes.map((w) => {
        const name = `${this.documentsName}/${w.path}`;
        const currentDocument = w.precondition;
        if ('delete' in w) return { delete: name, ...(currentDocument ? { currentDocument } : {}) };
        return {
          update: { name, fields: toFields(w.set) },
          ...(w.mask ? { updateMask: { fieldPaths: w.mask } } : {}),
          ...(currentDocument ? { currentDocument } : {}),
        };
      }),
    };
    const res = await this.fetchFn(`${this.base}:commit`, {
      method: 'POST',
      headers: await this.headers(),
      body: JSON.stringify(body),
    });
    if (res.ok) return;
    const text = await res.text();
    // 前提が崩れた（ほかの場所で先に変わった・もうある・もうない）
    if (res.status === 409 || /FAILED_PRECONDITION|ALREADY_EXISTS|NOT_FOUND/.test(text)) throw new ConflictError(text);
    throw new Error(`Firestore に書けませんでした（${res.status}）：${text}`);
  }
}
