// src/portfolio.ts
//
// 本人のデータの読み書き（Firestore の形は docs/plan/data-model.md の 3.）
//   users/{uid}                 … 本人の情報（slug・作った日・更新した日・版の番号）
//   users/{uid}/drafts/current  … 編集中のデータ 1 件（profile・skills・projects・display）
//   publicPages/{slug}          … 公開ページ（誰でも読める。書くのは「公開」のとき。段階 5 以降）
// - 読み書きできるのは、確かめたトークンの uid の文書だけ（パスは uid から作る。ほかの人の uid を受け取らない）
// - 書く前に必ず形を確かめる（validate.ts）
// - 同時に変えたとき：編集中のデータ全体の保存は、読んだときの updatedAt と違えば 409（上書きしない）。
//   プロフィールなどのまとまりごとの保存は、ほかのまとまりを消さないよう、読み直して数回やり直す
import { ApiError, ConflictError, badRequest, conflict, notFound } from './errors.ts';
import { missingForPublish, publicDataOf } from './publish.ts';
import type { DocStore, StoredDoc, Write } from './firestore.ts';
import {
  validateDisplay,
  validateDraftData,
  validateProfile,
  validateProject,
  validateSkills,
  type Errors,
} from './validate.ts';

export type DraftData = {
  schemaVersion: 1;
  profile: Record<string, unknown>;
  skills: Record<string, unknown>;
  projects: Record<string, unknown>[];
  display: Record<string, unknown>;
};

export type Draft = {
  data: DraftData;
  /** 最後に保存した時刻（ISO 8601）。まだ保存していなければ null。保存するときに送り返す */
  updatedAt: string | null;
};

/** まとまりごとに読み書きできるもの */
export type Section = 'profile' | 'skills' | 'display';

const SECTION_VALIDATORS: Record<Section, (v: unknown) => Errors> = {
  profile: validateProfile,
  skills: validateSkills,
  display: validateDisplay,
};

/** 本人の情報 */
export type Me = {
  slug: string | null;
  latestVersion: number;
  publishedVersion: number | null;
  updatedAt: string | null;
};

/** 公開ページの名前：英小文字・数字・-、3〜40 文字、先頭と最後は英小文字か数字 */
const SLUG = /^[a-z0-9][a-z0-9-]{1,38}[a-z0-9]$/;
/** 画面の URL・よくある名前と重ならないよう、使えない名前 */
const RESERVED_SLUGS = new Set(['me', 'login', 'signup', 'api', 'auth', 'u', 'admin', 'public', 'www', 'healthz', 'reset-password']);

/** まとまりごとの保存で、ほかの場所と重なったときにやり直す回数 */
const MAX_RETRIES = 3;

export const emptyDraftData = (): DraftData => ({ schemaVersion: 1, profile: {}, skills: {}, projects: [], display: {} });

const draftPath = (uid: string) => `users/${uid}/drafts/current`;
const userPath = (uid: string) => `users/${uid}`;

function ensureValid(errors: Errors) {
  if (errors.length > 0) throw badRequest('データの形が正しくありません', errors);
}

function normalize(data: Record<string, unknown>): DraftData {
  return {
    schemaVersion: 1,
    profile: (data.profile as Record<string, unknown>) ?? {},
    skills: (data.skills as Record<string, unknown>) ?? {},
    projects: (data.projects as Record<string, unknown>[]) ?? [],
    display: (data.display as Record<string, unknown>) ?? {},
  };
}

export class PortfolioService {
  private readonly store: DocStore;
  private readonly now: () => Date;
  private readonly newId: () => string;

  constructor(
    store: DocStore,
    options: { now?: () => Date; newId?: () => string } = {},
  ) {
    this.store = store;
    this.now = options.now ?? (() => new Date());
    this.newId = options.newId ?? (() => `p_${crypto.randomUUID().replaceAll('-', '').slice(0, 20)}`);
  }

  // ---------------- 編集中のデータ ----------------

  private async readDraft(uid: string): Promise<{ draft: Draft; doc: StoredDoc | null }> {
    const doc = await this.store.get(draftPath(uid));
    if (!doc) return { draft: { data: emptyDraftData(), updatedAt: null }, doc: null };
    return {
      draft: { data: normalize((doc.data.data as Record<string, unknown>) ?? {}), updatedAt: (doc.data.updatedAt as string) ?? null },
      doc,
    };
  }

  /** 編集中のデータ（まだなければ空） */
  async getDraft(uid: string): Promise<Draft> {
    return (await this.readDraft(uid)).draft;
  }

  /** 書く：編集中のデータと、本人の情報（はじめてなら作る） */
  private async writeDraft(uid: string, data: DraftData, doc: StoredDoc | null): Promise<Draft> {
    ensureValid(validateDraftData(data));
    const now = this.now();
    const user = await this.store.get(userPath(uid));
    const writes: Write[] = [
      {
        path: draftPath(uid),
        set: { data, updatedAt: now, baseVersion: (doc?.data.baseVersion as number | undefined) ?? 0 },
        // 読んだときから変わっていない（まだなければ、まだない）ときだけ書く
        precondition: doc ? { updateTime: doc.updateTime } : { exists: false },
      },
      user
        ? { path: userPath(uid), set: { updatedAt: now }, mask: ['updatedAt'], precondition: { updateTime: user.updateTime } }
        : {
            path: userPath(uid),
            set: { slug: null, createdAt: now, updatedAt: now, latestVersion: 0, publishedVersion: null },
            precondition: { exists: false },
          },
    ];
    await this.store.commit(writes);
    return { data, updatedAt: now.toISOString() };
  }

  /**
   * 編集中のデータ全体を保存する（自動の保存）
   * [expectedUpdatedAt] は読んだときの updatedAt（はじめてなら null）。違えば 409（別のタブ・端末で先に変わった）
   */
  async saveDraft(uid: string, data: unknown, expectedUpdatedAt: string | null): Promise<Draft> {
    ensureValid(validateDraftData(data));
    const { draft, doc } = await this.readDraft(uid);
    if (draft.updatedAt !== expectedUpdatedAt) throw conflict();
    try {
      return await this.writeDraft(uid, normalize(data as Record<string, unknown>), doc);
    } catch (e) {
      if (e instanceof ConflictError) throw conflict();
      throw e;
    }
  }

  /** 読み直して変えて書く。ほかの場所と重なったら数回やり直す */
  private async update(uid: string, change: (data: DraftData) => DraftData): Promise<Draft> {
    for (let attempt = 1; ; attempt++) {
      const { draft, doc } = await this.readDraft(uid);
      try {
        return await this.writeDraft(uid, change(structuredClone(draft.data)), doc);
      } catch (e) {
        if (!(e instanceof ConflictError)) throw e;
        if (attempt >= MAX_RETRIES) throw conflict();
      }
    }
  }

  // ---------------- プロフィール・スキル・表示設定 ----------------

  async getSection(uid: string, section: Section): Promise<Record<string, unknown>> {
    return (await this.getDraft(uid)).data[section];
  }

  async putSection(uid: string, section: Section, value: unknown): Promise<Record<string, unknown>> {
    ensureValid(SECTION_VALIDATORS[section](value));
    if (value === undefined) throw badRequest('中身がありません');
    const saved = await this.update(uid, (data) => ({ ...data, [section]: value as Record<string, unknown> }));
    return saved.data[section];
  }

  // ---------------- 職務経歴 ----------------

  async listProjects(uid: string): Promise<Record<string, unknown>[]> {
    return (await this.getDraft(uid)).data.projects;
  }

  /** 1 件足す。id がなければ作り、順番（order）は同じ種類の最後 */
  async addProject(uid: string, input: unknown): Promise<Record<string, unknown>> {
    if (typeof input !== 'object' || input === null || Array.isArray(input)) {
      throw badRequest('データの形が正しくありません', ['project：「項目: 値」の形で書いてください']);
    }
    let added: Record<string, unknown> | undefined;
    await this.update(uid, (data) => {
      const raw = input as Record<string, unknown>;
      const sameKind = data.projects.filter((p) => p.kind === raw.kind);
      const project = {
        ...raw,
        id: raw.id ?? this.newId(),
        order: raw.order ?? (sameKind.length === 0 ? 0 : Math.max(...sameKind.map((p) => Number(p.order) || 0)) + 1),
      };
      ensureValid(validateProject(project));
      if (data.projects.some((p) => p.id === project.id)) {
        throw new ApiError(409, 'duplicate_id', `同じ id のプロジェクトがもうあります（${String(project.id)}）`);
      }
      added = project;
      return { ...data, projects: [...data.projects, project] };
    });
    return added!;
  }

  /** 1 件を置き換える（id は変えられない） */
  async updateProject(uid: string, id: string, input: unknown): Promise<Record<string, unknown>> {
    if (typeof input !== 'object' || input === null || Array.isArray(input)) {
      throw badRequest('データの形が正しくありません', ['project：「項目: 値」の形で書いてください']);
    }
    let updated: Record<string, unknown> | undefined;
    await this.update(uid, (data) => {
      const index = data.projects.findIndex((p) => p.id === id);
      if (index < 0) throw notFound('プロジェクトが見つかりません');
      const project = { ...(input as Record<string, unknown>), id };
      ensureValid(validateProject(project));
      updated = project;
      const projects = [...data.projects];
      projects[index] = project;
      return { ...data, projects };
    });
    return updated!;
  }

  async deleteProject(uid: string, id: string): Promise<void> {
    await this.update(uid, (data) => {
      if (!data.projects.some((p) => p.id === id)) throw notFound('プロジェクトが見つかりません');
      return { ...data, projects: data.projects.filter((p) => p.id !== id) };
    });
  }

  // ---------------- 本人の情報・公開ページの名前・公開 ----------------

  /** 本人の情報（まだ何も保存していなければ既定の値） */
  async getMe(uid: string): Promise<Me> {
    const user = await this.store.get(userPath(uid));
    return {
      slug: (user?.data.slug as string | null) ?? null,
      latestVersion: (user?.data.latestVersion as number | undefined) ?? 0,
      publishedVersion: (user?.data.publishedVersion as number | null | undefined) ?? null,
      updatedAt: (user?.data.updatedAt as string | undefined) ?? null,
    };
  }

  /** 公開ページの名前（slug）を決める・変える。ほかの人が使っていれば 409。公開中なら公開ページも移す */
  async setSlug(uid: string, slug: unknown): Promise<Me> {
    if (typeof slug !== 'string' || !SLUG.test(slug) || RESERVED_SLUGS.has(slug)) {
      throw badRequest('公開ページの名前が正しくありません', [
        'slug：英小文字・数字・- の 3〜40 文字（先頭と最後は英小文字か数字）。me・login などは使えません',
      ]);
    }
    const user = await this.store.get(userPath(uid));
    const old = (user?.data.slug as string | null | undefined) ?? null;
    if (old === slug) return this.getMe(uid);

    const now = this.now();
    const writes: Write[] = [{ path: `slugs/${slug}`, set: { uid }, precondition: { exists: false } }];
    if (old) writes.push({ path: `slugs/${old}`, delete: true });
    writes.push(
      user
        ? { path: userPath(uid), set: { slug, updatedAt: now }, mask: ['slug', 'updatedAt'], precondition: { updateTime: user.updateTime } }
        : {
            path: userPath(uid),
            set: { slug, createdAt: now, updatedAt: now, latestVersion: 0, publishedVersion: null },
            precondition: { exists: false },
          },
    );
    // 公開中なら、公開ページも新しい名前に移す
    const page = old ? await this.store.get(`publicPages/${old}`) : null;
    if (page && old) {
      writes.push({ path: `publicPages/${slug}`, set: page.data }, { path: `publicPages/${old}`, delete: true });
    }
    try {
      await this.store.commit(writes);
    } catch (e) {
      if (e instanceof ConflictError) {
        throw new ApiError(409, 'slug_taken', 'この名前はもう使われています。別の名前にしてください');
      }
      throw e;
    }
    return this.getMe(uid);
  }

  /**
   * 公開する：今の編集中のデータを版として残し、公開する項目だけを取り出して公開ページにする
   * 名前（slug）がない・必須の項目が足りないときは公開しない
   */
  async publish(uid: string): Promise<Me> {
    const user = await this.store.get(userPath(uid));
    const slug = (user?.data.slug as string | null | undefined) ?? null;
    if (!user || !slug) throw new ApiError(409, 'slug_required', '先に公開ページの名前を決めてください');
    const { draft, doc } = await this.readDraft(uid);
    if (!doc) throw new ApiError(409, 'nothing_to_publish', 'まだ何も保存していません');
    const missing = missingForPublish(draft.data);
    if (missing.length > 0) throw badRequest('公開ページに必要な項目が足りません', missing);

    const number = ((user.data.latestVersion as number | undefined) ?? 0) + 1;
    const now = this.now();
    try {
      await this.store.commit([
        {
          path: `users/${uid}/versions/${number}`,
          set: { number, data: draft.data, note: '公開', source: 'publish', createdAt: now },
          precondition: { exists: false },
        },
        { path: `users/${uid}/drafts/current`, set: { baseVersion: number }, mask: ['baseVersion'], precondition: { updateTime: doc.updateTime } },
        {
          path: userPath(uid),
          set: { latestVersion: number, publishedVersion: number, updatedAt: now },
          mask: ['latestVersion', 'publishedVersion', 'updatedAt'],
          precondition: { updateTime: user.updateTime },
        },
        { path: `publicPages/${slug}`, set: { data: publicDataOf(draft.data), version: number, publishedAt: now } },
      ]);
    } catch (e) {
      if (e instanceof ConflictError) throw conflict();
      throw e;
    }
    return this.getMe(uid);
  }

  /** 公開を止める（公開ページを消す。版は残す） */
  async unpublish(uid: string): Promise<Me> {
    const user = await this.store.get(userPath(uid));
    const slug = (user?.data.slug as string | null | undefined) ?? null;
    if (!user || !slug || user.data.publishedVersion == null) return this.getMe(uid);
    await this.store.commit([
      { path: `publicPages/${slug}`, delete: true },
      { path: userPath(uid), set: { publishedVersion: null, updatedAt: this.now() }, mask: ['publishedVersion', 'updatedAt'] },
    ]);
    return this.getMe(uid);
  }

  /** 退会：本人のデータをすべて消す（版・編集中・本人の情報・公開ページ・名前）。アカウントは認証（Phoenix）で消す */
  async deleteAll(uid: string): Promise<void> {
    const user = await this.store.get(userPath(uid));
    const slug = (user?.data.slug as string | null | undefined) ?? null;
    const versions = await this.store.list(`users/${uid}/versions`);
    const writes: Write[] = [
      ...versions.map((path): Write => ({ path, delete: true })),
      { path: draftPath(uid), delete: true },
      { path: userPath(uid), delete: true },
    ];
    if (slug) writes.push({ path: `slugs/${slug}`, delete: true }, { path: `publicPages/${slug}`, delete: true });
    // 1 回の commit は 500 件まで
    for (let i = 0; i < writes.length; i += 500) await this.store.commit(writes.slice(i, i + 500));
  }

  // ---------------- 公開ページ（誰でも読める） ----------------

  async getPublicPage(slug: string): Promise<Record<string, unknown>> {
    // ない・公開していないは区別しない（docs/plan/requirements.md の PUB-04）
    if (!SLUG.test(slug)) throw notFound();
    const doc = await this.store.get(`publicPages/${slug}`);
    if (!doc) throw notFound();
    return { data: doc.data.data, version: doc.data.version, publishedAt: doc.data.publishedAt };
  }
}
