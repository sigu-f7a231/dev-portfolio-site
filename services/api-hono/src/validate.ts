// src/validate.ts
//
// 受け取ったデータの形を確かめる（画面の確認だけに頼らない。docs/plan/requirements.md の API-08）
// 形は docs/plan/data-model.md の 2.（項目と型）。編集中のデータなので、必須の項目が空でもよい（公開のときに確かめる）
// 誤りは「どこが・どう違うか」の一覧で返す（例：profile.home.name：100 文字までです）

export type Errors = string[];

type Obj = Record<string, unknown>;

/** 技術の分類（YAML のキーと同じ） */
export const TECH_CATEGORIES = [
  'server_os', 'db', 'tools', 'backend_frameworks', 'frontend_frameworks', 'ui_frameworks', 'testing_frameworks',
  'cloud_platforms', 'aws_services', 'azure_services', 'gcp_services', 'container', 'container_orchestration',
  'ai_services', 'skills',
] as const;

/** 担当の工程（Work だけ） */
export const WORKFLOW_KEYS = [
  'requirements', 'basic_design', 'detailed_design', 'implementation_unit_test', 'integration_test', 'system_test',
  'maintenance_operation',
] as const;

/** スキルシートだけの項目（公開しない） */
export const SHEET_KEYS = ['furigana', 'gender', 'age', 'birthday', 'nationality', 'spouse', 'station', 'education'] as const;

export const LIMITS = {
  shortText: 100,
  longText: 5000,
  listItems: 50,
  projects: 200,
  /** 1 件の文書の上限（1 MiB）より小さく */
  draftBytes: 900_000,
};

const isObj = (v: unknown): v is Obj => typeof v === 'object' && v !== null && !Array.isArray(v);

function unknownKeys(errors: Errors, at: string, value: Obj, allowed: readonly string[]) {
  for (const key of Object.keys(value)) {
    if (!allowed.includes(key)) errors.push(`${at}.${key}：知らない項目です`);
  }
}

function text(errors: Errors, at: string, v: unknown, max: number) {
  if (v === undefined) return;
  if (typeof v !== 'string') errors.push(`${at}：文字で書いてください`);
  else if (v.length > max) errors.push(`${at}：${max} 文字までです`);
}

function textList(errors: Errors, at: string, v: unknown, maxItems = LIMITS.listItems) {
  if (v === undefined) return;
  if (!Array.isArray(v)) return errors.push(`${at}：並び（[...]）で書いてください`);
  if (v.length > maxItems) errors.push(`${at}：${maxItems} 個までです`);
  v.forEach((item, i) => text(errors, `${at}[${i}]`, item, LIMITS.shortText));
}

function bool(errors: Errors, at: string, v: unknown) {
  if (v !== undefined && typeof v !== 'boolean') errors.push(`${at}：true か false で書いてください`);
}

function oneOf(errors: Errors, at: string, v: unknown, values: readonly string[]) {
  if (v !== undefined && (typeof v !== 'string' || !values.includes(v))) {
    errors.push(`${at}：${values.join(' / ')} のどれかです`);
  }
}

function section(errors: Errors, at: string, v: unknown): Obj | undefined {
  if (v === undefined) return undefined;
  if (!isObj(v)) {
    errors.push(`${at}：「項目: 値」の形で書いてください`);
    return undefined;
  }
  return v;
}

const YEAR_MONTH = /^\d{4}-(0[1-9]|1[0-2])$/;
const DATE = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;
const PROJECT_ID = /^[A-Za-z0-9_-]{1,64}$/;

// ---------------- 各まとまり ----------------

export function validateProfile(v: unknown, at = 'profile'): Errors {
  const errors: Errors = [];
  const profile = section(errors, at, v);
  if (!profile) return errors;
  unknownKeys(errors, at, profile, ['home', 'about', 'sheet']);

  const home = section(errors, `${at}.home`, profile.home);
  if (home) {
    unknownKeys(errors, `${at}.home`, home, ['name', 'role', 'tagline']);
    text(errors, `${at}.home.name`, home.name, LIMITS.shortText);
    text(errors, `${at}.home.role`, home.role, LIMITS.shortText);
    text(errors, `${at}.home.tagline`, home.tagline, LIMITS.longText);
  }

  const about = section(errors, `${at}.about`, profile.about);
  if (about) {
    unknownKeys(errors, `${at}.about`, about, ['intro', 'domains', 'strengths', 'style', 'closing', 'recent', 'past']);
    for (const key of ['intro', 'strengths', 'style', 'closing', 'recent', 'past']) {
      text(errors, `${at}.about.${key}`, about[key], LIMITS.longText);
    }
    textList(errors, `${at}.about.domains`, about.domains);
  }

  const sheet = section(errors, `${at}.sheet`, profile.sheet);
  if (sheet) {
    unknownKeys(errors, `${at}.sheet`, sheet, SHEET_KEYS);
    for (const key of SHEET_KEYS) text(errors, `${at}.sheet.${key}`, sheet[key], LIMITS.shortText);
    if (typeof sheet.birthday === 'string' && sheet.birthday !== '' && !DATE.test(sheet.birthday)) {
      errors.push(`${at}.sheet.birthday：YYYY-MM-DD の形で書いてください`);
    }
  }
  return errors;
}

function techMap(errors: Errors, at: string, v: unknown) {
  const map = section(errors, at, v);
  if (!map) return;
  unknownKeys(errors, at, map, TECH_CATEGORIES);
  for (const key of TECH_CATEGORIES) textList(errors, `${at}.${key}`, map[key]);
}

/** 主な技術（分類 → 技術）。分類の名前は自由（Excel から読むと「言語」などの日本語になる）。30 分類まで */
function groupMap(errors: Errors, at: string, v: unknown) {
  const map = section(errors, at, v);
  if (!map) return;
  const keys = Object.keys(map);
  if (keys.length > 30) errors.push(`${at}：30 分類までです`);
  for (const key of keys) {
    if (key.trim() === '' || key.length > 50) errors.push(`${at}：分類の名前は 1〜50 文字です（${key.slice(0, 50)}）`);
    textList(errors, `${at}.${key}`, map[key]);
  }
}

export function validateSkills(v: unknown, at = 'skills'): Errors {
  const errors: Errors = [];
  const skills = section(errors, at, v);
  if (!skills) return errors;
  unknownKeys(errors, at, skills, ['recentTech', 'pastTech']);
  groupMap(errors, `${at}.recentTech`, skills.recentTech);
  groupMap(errors, `${at}.pastTech`, skills.pastTech);
  return errors;
}

export function validateProject(v: unknown, at = 'project'): Errors {
  const errors: Errors = [];
  if (!isObj(v)) return [`${at}：「項目: 値」の形で書いてください`];
  unknownKeys(errors, at, v, [
    'id', 'kind', 'order', 'title', 'description', 'details', 'role', 'scale', 'period', 'link', 'tech', 'workflow',
  ]);
  if (typeof v.id !== 'string' || !PROJECT_ID.test(v.id)) errors.push(`${at}.id：英数字・_・- の 64 文字までです`);
  if (v.kind !== 'work' && v.kind !== 'private') errors.push(`${at}.kind：work か private です`);
  if (typeof v.order !== 'number' || !Number.isInteger(v.order) || v.order < 0) {
    errors.push(`${at}.order：0 以上の整数です`);
  }
  if (typeof v.title !== 'string' || v.title.trim() === '') errors.push(`${at}.title：プロジェクト名を書いてください`);
  else text(errors, `${at}.title`, v.title, LIMITS.shortText);
  text(errors, `${at}.description`, v.description, LIMITS.longText);
  text(errors, `${at}.details`, v.details, LIMITS.longText);
  textList(errors, `${at}.role`, v.role);
  text(errors, `${at}.scale`, v.scale, LIMITS.shortText);

  const period = section(errors, `${at}.period`, v.period);
  if (period) {
    unknownKeys(errors, `${at}.period`, period, ['start', 'end']);
    if (typeof period.start !== 'string' || !YEAR_MONTH.test(period.start)) {
      errors.push(`${at}.period.start：YYYY-MM の形で書いてください`);
    }
    if (period.end !== null && (typeof period.end !== 'string' || !YEAR_MONTH.test(period.end))) {
      errors.push(`${at}.period.end：YYYY-MM の形か、進行中なら null です`);
    } else if (typeof period.start === 'string' && typeof period.end === 'string' && period.end < period.start) {
      errors.push(`${at}.period：終わりが始まりより前です`);
    }
  }

  if (v.link !== undefined && v.link !== '') {
    if (typeof v.link !== 'string' || !/^https:\/\/\S+$/.test(v.link)) errors.push(`${at}.link：https:// で始まる URL です`);
  }
  techMap(errors, `${at}.tech`, v.tech);

  if (v.workflow !== undefined) {
    if (v.kind === 'private') errors.push(`${at}.workflow：Private には書きません`);
    const workflow = section(errors, `${at}.workflow`, v.workflow);
    if (workflow) {
      unknownKeys(errors, `${at}.workflow`, workflow, WORKFLOW_KEYS);
      for (const key of WORKFLOW_KEYS) bool(errors, `${at}.workflow.${key}`, workflow[key]);
    }
  }
  return errors;
}

export function validateProjects(v: unknown, at = 'projects'): Errors {
  if (!Array.isArray(v)) return [`${at}：並び（[...]）で書いてください`];
  const errors: Errors = [];
  if (v.length > LIMITS.projects) errors.push(`${at}：${LIMITS.projects} 件までです`);
  const seen = new Set<string>();
  v.forEach((p, i) => {
    errors.push(...validateProject(p, `${at}[${i}]`));
    if (isObj(p) && typeof p.id === 'string') {
      if (seen.has(p.id)) errors.push(`${at}[${i}].id：同じ id がほかにもあります（${p.id}）`);
      seen.add(p.id);
    }
  });
  return errors;
}

export function validateDisplay(v: unknown, at = 'display'): Errors {
  const errors: Errors = [];
  const display = section(errors, at, v);
  if (!display) return errors;
  unknownKeys(errors, at, display, ['sections', 'home', 'about', 'skills', 'projects', 'allowSheetDownload', 'theme']);

  if (display.sections !== undefined) {
    if (!Array.isArray(display.sections)) errors.push(`${at}.sections：並び（[...]）で書いてください`);
    else {
      display.sections.forEach((s, i) => {
        const item = section(errors, `${at}.sections[${i}]`, s);
        if (!item) return;
        unknownKeys(errors, `${at}.sections[${i}]`, item, ['id', 'visible']);
        oneOf(errors, `${at}.sections[${i}].id`, item.id ?? '', ['about', 'skills', 'projects']);
        bool(errors, `${at}.sections[${i}].visible`, item.visible);
      });
    }
  }
  for (const key of ['home', 'about']) {
    const flags = section(errors, `${at}.${key}`, display[key]);
    if (flags) for (const [k, flag] of Object.entries(flags)) bool(errors, `${at}.${key}.${k}`, flag);
  }
  const skills = section(errors, `${at}.skills`, display.skills);
  if (skills) {
    unknownKeys(errors, `${at}.skills`, skills, ['categories', 'initial']);
    textList(errors, `${at}.skills.categories`, skills.categories);
    text(errors, `${at}.skills.initial`, skills.initial, LIMITS.shortText);
  }
  const projects = section(errors, `${at}.projects`, display.projects);
  if (projects) {
    unknownKeys(errors, `${at}.projects`, projects, ['tabs', 'hidden', 'fields', 'view', 'sort']);
    const tabs = section(errors, `${at}.projects.tabs`, projects.tabs);
    if (tabs) {
      unknownKeys(errors, `${at}.projects.tabs`, tabs, ['work', 'private']);
      bool(errors, `${at}.projects.tabs.work`, tabs.work);
      bool(errors, `${at}.projects.tabs.private`, tabs.private);
    }
    textList(errors, `${at}.projects.hidden`, projects.hidden, LIMITS.projects);
    const fields = section(errors, `${at}.projects.fields`, projects.fields);
    if (fields) {
      unknownKeys(errors, `${at}.projects.fields`, fields, ['details', 'link', 'role', 'scale']);
      for (const [k, flag] of Object.entries(fields)) bool(errors, `${at}.projects.fields.${k}`, flag);
    }
    oneOf(errors, `${at}.projects.view`, projects.view, ['list', 'collection']);
    text(errors, `${at}.projects.sort`, projects.sort, LIMITS.shortText);
  }
  bool(errors, `${at}.allowSheetDownload`, display.allowSheetDownload);
  oneOf(errors, `${at}.theme`, display.theme, ['light', 'dark', 'system']);
  return errors;
}

/** 編集中のデータ全体（schemaVersion・profile・skills・projects・display） */
export function validateDraftData(v: unknown): Errors {
  if (!isObj(v)) return ['data：「項目: 値」の形で書いてください'];
  const errors: Errors = [];
  unknownKeys(errors, 'data', v, ['schemaVersion', 'profile', 'skills', 'projects', 'display']);
  if (v.schemaVersion !== undefined && v.schemaVersion !== 1) errors.push('data.schemaVersion：1 です');
  errors.push(...validateProfile(v.profile, 'data.profile'));
  errors.push(...validateSkills(v.skills, 'data.skills'));
  if (v.projects !== undefined) errors.push(...validateProjects(v.projects, 'data.projects'));
  errors.push(...validateDisplay(v.display, 'data.display'));
  if (new TextEncoder().encode(JSON.stringify(v)).length > LIMITS.draftBytes) {
    errors.push(`data：大きすぎます（${LIMITS.draftBytes} バイトまで）`);
  }
  return errors;
}
