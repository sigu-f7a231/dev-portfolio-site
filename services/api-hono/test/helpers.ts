// test/helpers.ts
//
// テストの道具（ファイル名が .test.ts で終わらないので、これ自体はテストとして動かない）
// - MemoryStore：DocStore のメモリ上の偽物（Firestore の前提条件 exists / updateTime も同じように確かめる）
// - unsignedToken：Auth Emulator と同じ、署名のない ID トークンを作る
import { ConflictError } from '../src/errors.ts';
import type { DocStore, Precondition, StoredDoc, Write } from '../src/firestore.ts';

export class MemoryStore implements DocStore {
  readonly docs = new Map<string, StoredDoc>();
  readonly commits: Write[][] = [];
  private clock = 0;
  /** 次の commit の前に呼ぶ（ほかの場所が先に書いたことにするため） */
  beforeCommit?: () => void;

  async get(path: string): Promise<StoredDoc | null> {
    const doc = this.docs.get(path);
    return doc ? structuredClone(doc) : null;
  }

  /** テストから直接書く（ほかの場所が書いたことにする） */
  put(path: string, data: Record<string, unknown>) {
    this.docs.set(path, { data: structuredClone(data), updateTime: this.tick() });
  }

  private tick() {
    this.clock += 1;
    return `2026-11-06T00:00:00.${String(this.clock).padStart(6, '0')}Z`;
  }

  private check(path: string, pre?: Precondition) {
    if (!pre) return;
    const doc = this.docs.get(path);
    if ('exists' in pre && pre.exists !== Boolean(doc)) throw new ConflictError(`${path}: exists`);
    if ('updateTime' in pre && doc?.updateTime !== pre.updateTime) throw new ConflictError(`${path}: updateTime`);
  }

  async commit(writes: Write[]): Promise<void> {
    const hook = this.beforeCommit;
    this.beforeCommit = undefined;
    hook?.();
    for (const w of writes) this.check(w.path, w.precondition);
    this.commits.push(structuredClone(writes));
    for (const w of writes) {
      if ('delete' in w) {
        this.docs.delete(w.path);
        continue;
      }
      const set = JSON.parse(JSON.stringify(w.set)) as Record<string, unknown>; // Date → 文字（Firestore から読んだときと同じ）
      const before = this.docs.get(w.path)?.data ?? {};
      const data = w.mask ? { ...before, ...Object.fromEntries(w.mask.map((k) => [k, set[k]])) } : set;
      this.docs.set(w.path, { data, updateTime: this.tick() });
    }
  }
}

const b64url = (obj: object) => Buffer.from(JSON.stringify(obj)).toString('base64url');

/** Auth Emulator と同じ、署名のない ID トークン（alg: none） */
export function unsignedToken(claims: Record<string, unknown>) {
  return `${b64url({ alg: 'none', typ: 'JWT' })}.${b64url(claims)}.`;
}

export const PROJECT = 'demo-test';

/** 正しい中身の ID トークンの claims（[overrides] で一部を変える） */
export function claimsFor(uid: string, overrides: Record<string, unknown> = {}, now = Math.floor(Date.now() / 1000)) {
  return {
    iss: `https://securetoken.google.com/${PROJECT}`,
    aud: PROJECT,
    sub: uid,
    user_id: uid,
    auth_time: now - 10,
    iat: now - 10,
    exp: now + 3600,
    ...overrides,
  };
}

/** 正しい Work のプロジェクト 1 件 */
export const workProject = {
  id: 'p_work_1',
  kind: 'work',
  order: 0,
  title: 'サンプル・ワーク',
  description: '概要',
  details: '詳細',
  role: ['PG'],
  scale: '全体 10名',
  period: { start: '2023-04', end: '2023-09' },
  link: 'https://example.com/work',
  tech: { skills: ['Python'], db: ['PostgreSQL'] },
  workflow: { basic_design: true, implementation_unit_test: true },
};
