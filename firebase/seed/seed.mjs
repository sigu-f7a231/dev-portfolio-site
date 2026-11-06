// firebase/seed/seed.mjs
//
// Firebase Emulator に、動作確認用のサンプル（個人の情報は入れない）を入れる
//   docker compose run --rm seed
// - Auth：サンプルの利用者（sample.json の user。Emulator の中だけのアカウント）
// - Firestore：docs/plan/data-model.md の形で users/{uid}・drafts/current・versions/1・slugs/{slug}・publicPages/{slug}
// - 何度実行しても同じ中身になる（あれば上書き）
// - 本物の Firebase には書かない（つなぎ先は Emulator だけ。下の 2 つの環境変数がないと止まる）
// 依存するパッケージはない（Node 22 の fetch だけ）。
import { readFile } from 'node:fs/promises';


/** JavaScript の値 → Firestore の REST の値（https://firebase.google.com/docs/firestore/reference/rest/v1/Value） */
export function toValue(v) {
  if (v === null || v === undefined) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return Number.isInteger(v) ? { integerValue: String(v) } : { doubleValue: v };
  if (typeof v === 'string') return { stringValue: v };
  if (v instanceof Date) return { timestampValue: v.toISOString() };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(toValue) } };
  return { mapValue: { fields: toFields(v) } };
}

/** オブジェクト → Firestore の文書の fields */
export function toFields(obj) {
  return Object.fromEntries(Object.entries(obj).map(([k, v]) => [k, toValue(v)]));
}

/** 公開する項目だけを取り出す（docs/plan/data-model.md の 4.：スキルシートだけの項目 sheet は必ず外す） */
export function publicDataOf(data) {
  const { sheet: _sheet, ...profile } = data.profile;
  const hidden = new Set(data.display?.projects?.hidden ?? []);
  return { ...data, profile, projects: data.projects.filter((p) => !hidden.has(p.id)) };
}

async function request(url, { method = 'GET', body, owner = false } = {}) {
  const res = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
      // Emulator だけで使える「管理者として」の印。セキュリティルールを通らずに書ける
      ...(owner ? { Authorization: 'Bearer owner' } : {}),
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const json = await res.json().catch(() => ({}));
  return { ok: res.ok, status: res.status, json };
}

/** サンプルの利用者を作る（もういれば、その uid を使う） */
async function ensureUser(authHost, { email, password, displayName }) {
  const base = `http://${authHost}/identitytoolkit.googleapis.com/v1`;
  const key = 'key=demo'; // Emulator は API キーを確かめない
  const signUp = await request(`${base}/accounts:signUp?${key}`, {
    method: 'POST',
    body: { email, password, displayName, returnSecureToken: true },
  });
  if (signUp.ok) return signUp.json.localId;
  if (signUp.json?.error?.message !== 'EMAIL_EXISTS') {
    throw new Error(`利用者を作れませんでした（${signUp.status}）：${JSON.stringify(signUp.json)}`);
  }
  const signIn = await request(`${base}/accounts:signInWithPassword?${key}`, {
    method: 'POST',
    body: { email, password, returnSecureToken: true },
  });
  if (!signIn.ok) throw new Error(`利用者にログインできませんでした（${signIn.status}）：${JSON.stringify(signIn.json)}`);
  return signIn.json.localId;
}

/** 文書を書く（あれば上書き） */
async function setDoc(firestoreHost, project, path, data) {
  const url = `http://${firestoreHost}/v1/projects/${project}/databases/(default)/documents/${path}`;
  const res = await request(url, { method: 'PATCH', body: { fields: toFields(data) }, owner: true });
  if (!res.ok) throw new Error(`${path} を書けませんでした（${res.status}）：${JSON.stringify(res.json)}`);
  console.log(`  書きました：${path}`);
}

/**
 * サンプルを入れる。書いた文書のパスを返す
 * @param {{authHost: string, firestoreHost: string, project: string, sample: object, now?: Date}} options
 */
export async function seed({ authHost, firestoreHost, project, sample, now = new Date() }) {
  if (!authHost || !firestoreHost) {
    throw new Error('FIREBASE_AUTH_EMULATOR_HOST と FIRESTORE_EMULATOR_HOST を指定してください（Emulator にだけ書くため）');
  }
  console.log(`Firebase Emulator（${project}）にサンプルを入れます`);
  const uid = await ensureUser(authHost, sample.user);
  console.log(`  利用者：${sample.user.email}（uid ${uid}）`);

  const { slug } = sample.user;
  const data = { schemaVersion: 1, ...sample.data };
  const docs = [
    [`users/${uid}`, { slug, createdAt: now, updatedAt: now, latestVersion: 1, publishedVersion: 1 }],
    [`users/${uid}/drafts/current`, { data, baseVersion: 1, updatedAt: now }],
    [`users/${uid}/versions/1`, { number: 1, data, note: 'サンプル', source: 'yaml', createdAt: now }],
    [`slugs/${slug}`, { uid }],
    [`publicPages/${slug}`, { data: publicDataOf(data), version: 1, publishedAt: now }],
  ];
  for (const [path, doc] of docs) await setDoc(firestoreHost, project, path, doc);
  console.log('終わりました。確認用の画面：http://localhost:4001');
  return docs.map(([path]) => path);
}

async function main() {
  const sample = JSON.parse(await readFile(new URL('./sample.json', import.meta.url), 'utf8'));
  await seed({
    authHost: process.env.FIREBASE_AUTH_EMULATOR_HOST, // 例：firebase:9099
    firestoreHost: process.env.FIRESTORE_EMULATOR_HOST, // 例：firebase:8080
    project: process.env.FIREBASE_PROJECT ?? 'demo-dev-portfolio',
    sample,
  });
}

// テスト（seed.test.mjs）から import したときは実行しない
if (import.meta.url === `file://${process.argv[1]}`) {
  main().catch((e) => {
    console.error(e.message ?? e);
    process.exit(1);
  });
}
