// test/publish.test.ts … 公開ページのデータ（表示設定で隠したものを入れない・スキルシートの項目は必ず外す）
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { missingForPublish, publicDataOf } from '../src/publish.ts';
import { workProject } from './helpers.ts';

const full = {
  schemaVersion: 1,
  profile: {
    home: { name: '名前', role: '職種', tagline: '紹介' },
    about: { intro: '自己紹介', strengths: '強み', closing: '締め' },
    sheet: { furigana: 'なまえ', birthday: '1990-04-01' },
  },
  skills: { recentTech: { skills: ['Dart'] } },
  projects: [
    workProject,
    { id: 'p_private', kind: 'private', order: 0, title: '個人', link: 'https://example.com', scale: '1名' },
  ],
  display: {},
};

test('スキルシートだけの項目（sheet）は、表示設定によらず必ず外す', () => {
  const pub = publicDataOf(full) as { profile: Record<string, unknown> };
  assert.equal(pub.profile.sheet, undefined);
  assert.ok(full.profile.sheet, '元のデータは変えない');
});

test('表示設定がなければ、sheet 以外は全部出す', () => {
  const pub = publicDataOf(full) as { profile: { home: object; about: object }; projects: unknown[]; skills: object };
  assert.deepEqual(pub.profile.home, full.profile.home);
  assert.deepEqual(pub.profile.about, full.profile.about);
  assert.equal(pub.projects.length, 2);
  assert.deepEqual(pub.skills, full.skills);
});

test('Home / About で false にした項目を外す（名前は外さない）', () => {
  const pub = publicDataOf({ ...full, display: { home: { tagline: false, name: false }, about: { closing: false } } }) as {
    profile: { home: Record<string, unknown>; about: Record<string, unknown> };
  };
  assert.equal(pub.profile.home.tagline, undefined);
  assert.equal(pub.profile.home.name, '名前');
  assert.equal(pub.profile.about.closing, undefined);
  assert.equal(pub.profile.about.intro, '自己紹介');
});

test('About を出さないなら、About の中身と主な技術を外す', () => {
  const pub = publicDataOf({ ...full, display: { sections: [{ id: 'about', visible: false }] } }) as {
    profile: { about: object };
    skills: object;
  };
  assert.deepEqual(pub.profile.about, {});
  assert.deepEqual(pub.skills, {});
});

test('Projects：隠したプロジェクト・出さないタブ・出さない項目を外す', () => {
  const hidden = publicDataOf({ ...full, display: { projects: { hidden: [workProject.id] } } }) as { projects: { id: string }[] };
  assert.deepEqual(hidden.projects.map((p) => p.id), ['p_private']);

  const tab = publicDataOf({ ...full, display: { projects: { tabs: { private: false } } } }) as { projects: { id: string }[] };
  assert.deepEqual(tab.projects.map((p) => p.id), [workProject.id]);

  const fields = publicDataOf({ ...full, display: { projects: { fields: { link: false, scale: false, details: true } } } }) as {
    projects: Record<string, unknown>[];
  };
  for (const p of fields.projects) {
    assert.equal(p.link, undefined);
    assert.equal(p.scale, undefined);
  }
  assert.equal(fields.projects[0].details, workProject.details);
});

test('公開に必要な項目（名前・職種・紹介文・自己紹介）が足りなければ一覧で返す', () => {
  assert.deepEqual(missingForPublish(full), []);
  const missing = missingForPublish({ profile: { home: { name: ' ' } } });
  assert.equal(missing.length, 4);
  assert.ok(missing[0].startsWith('profile.home.name'));
  assert.equal(missingForPublish({}).length, 4);
});
