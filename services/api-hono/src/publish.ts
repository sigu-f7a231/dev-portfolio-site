// src/publish.ts
//
// 公開ページのデータを作る（docs/plan/requirements.md の PUB-02・PUB-03）
// 表示設定で隠したものは、画面で隠すだけでなく、公開ページのデータにも入れない
// - スキルシートだけの項目（profile.sheet）は、表示設定によらず必ず外す
// - Home / About：display.home / display.about で false にした項目を外す（名前は外さない）
// - About のセクションを出さない（display.sections の about が false）なら、About の中身を外す
// - Projects：隠したプロジェクト（display.projects.hidden）、出さないタブ（display.projects.tabs）の種類、
//   出さない項目（display.projects.fields の details・link・role・scale）を外す
// - Skills / Projects のセクションを出さない設定は、画面で隠す（Skills はプロジェクトから集計するので、プロジェクトは残す）
// - 表示設定（display）はそのまま入れる（画面がセクションの並び・既定の表示に使う）

type Obj = Record<string, unknown>;

const isObj = (v: unknown): v is Obj => typeof v === 'object' && v !== null && !Array.isArray(v);

function withoutFalse(values: Obj, flags: unknown, keep: string[] = []): Obj {
  if (!isObj(flags)) return values;
  return Object.fromEntries(Object.entries(values).filter(([k]) => keep.includes(k) || flags[k] !== false));
}

/** 公開してよい項目だけのデータ */
export function publicDataOf(data: Obj): Obj {
  const display = isObj(data.display) ? data.display : {};
  const profile = isObj(data.profile) ? data.profile : {};
  const sections = Array.isArray(display.sections) ? (display.sections as Obj[]) : [];
  const sectionVisible = (id: string) => !sections.some((s) => s.id === id && s.visible === false);

  const home = withoutFalse(isObj(profile.home) ? profile.home : {}, display.home, ['name']);
  const about = sectionVisible('about') ? withoutFalse(isObj(profile.about) ? profile.about : {}, display.about) : {};

  const projectsDisplay = isObj(display.projects) ? display.projects : {};
  const hidden = new Set(Array.isArray(projectsDisplay.hidden) ? (projectsDisplay.hidden as string[]) : []);
  const tabs = isObj(projectsDisplay.tabs) ? projectsDisplay.tabs : {};
  const fields = isObj(projectsDisplay.fields) ? projectsDisplay.fields : {};
  const projects = (Array.isArray(data.projects) ? (data.projects as Obj[]) : [])
    .filter((p) => !hidden.has(String(p.id)))
    .filter((p) => tabs[String(p.kind)] !== false)
    .map((p) => Object.fromEntries(Object.entries(p).filter(([k]) => !(k in fields) || fields[k] !== false)));

  const skills = sectionVisible('about') ? data.skills ?? {} : {}; // 主な技術は About に出すもの

  return { schemaVersion: 1, profile: { home, about }, skills, projects, display };
}

/** 公開するときに必要な項目（公開ページで必須の項目）。足りないものの一覧 */
export function missingForPublish(data: Obj): string[] {
  const profile = isObj(data.profile) ? data.profile : {};
  const home = isObj(profile.home) ? profile.home : {};
  const about = isObj(profile.about) ? profile.about : {};
  const blank = (v: unknown) => typeof v !== 'string' || v.trim() === '';
  const missing: string[] = [];
  if (blank(home.name)) missing.push('profile.home.name：名前を書いてください');
  if (blank(home.role)) missing.push('profile.home.role：職種を書いてください');
  if (blank(home.tagline)) missing.push('profile.home.tagline：紹介文を書いてください');
  if (blank(about.intro)) missing.push('profile.about.intro：自己紹介を書いてください');
  return missing;
}
