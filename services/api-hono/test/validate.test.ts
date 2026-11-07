// test/validate.test.ts … 受け取ったデータの形を確かめる（docs/plan/data-model.md の 2.）
import assert from 'node:assert/strict';
import { test } from 'node:test';

import {
  LIMITS,
  validateDisplay,
  validateDraftData,
  validateProfile,
  validateProject,
  validateProjects,
  validateSkills,
} from '../src/validate.ts';
import { workProject } from './helpers.ts';


const has = (errors: string[], part: string) =>
  assert.ok(errors.some((e) => e.includes(part)), `「${part}」を含む誤りがない：${JSON.stringify(errors)}`);

test('正常系：空の編集データ・全部書いたデータは通る', () => {
  assert.deepEqual(validateDraftData({}), []);
  assert.deepEqual(
    validateDraftData({
      schemaVersion: 1,
      profile: {
        home: { name: '名前', role: '職種', tagline: '紹介' },
        about: { intro: '自己紹介', domains: ['Web'], strengths: 's', style: 's', closing: 'c', recent: 'r', past: 'p' },
        sheet: { furigana: 'なまえ', birthday: '1990-04-01', station: '○○駅' },
      },
      skills: { recentTech: { skills: ['Dart'] }, pastTech: {} },
      projects: [workProject, { id: 'p2', kind: 'private', order: 0, title: '個人', period: { start: '2024-01', end: null } }],
      display: {
        sections: [{ id: 'about', visible: true }],
        home: { tagline: false },
        about: { closing: true },
        skills: { categories: ['skills'], initial: 'skills' },
        projects: { tabs: { work: true, private: false }, hidden: ['p2'], fields: { link: false }, view: 'list', sort: 'startNewest' },
        allowSheetDownload: false,
        theme: 'system',
      },
    }),
    [],
  );
});

test('プロフィール：型・長さ・知らない項目・生年月日の形', () => {
  has(validateProfile({ home: { name: 1 } }), 'profile.home.name：文字で');
  has(validateProfile({ home: { name: 'x'.repeat(LIMITS.shortText + 1) } }), '100 文字まで');
  has(validateProfile({ home: { nickname: 'x' } }), 'profile.home.nickname：知らない項目');
  has(validateProfile({ about: { domains: 'Web' } }), 'profile.about.domains：並び');
  has(validateProfile({ sheet: { birthday: '1990/4/1' } }), 'YYYY-MM-DD');
  has(validateProfile({ sheet: { address: '住所' } }), 'profile.sheet.address：知らない項目');
  has(validateProfile([]), 'profile：「項目: 値」');
  assert.deepEqual(validateProfile(undefined), []);
});

test('スキル：分類の名前は自由（日本語も）。中身は文字の並び、30 分類まで', () => {
  assert.deepEqual(validateSkills({ recentTech: { 言語: ['Dart'], frontend_frameworks: ['Flutter'] } }), []);
  has(validateSkills({ recentTech: { '': ['Dart'] } }), '分類の名前は 1〜50 文字');
  has(validateSkills({ recentTech: Object.fromEntries(Array.from({ length: 31 }, (_, i) => [`c${i}`, []])) }), '30 分類まで');
  has(validateSkills({ pastTech: { skills: [1] } }), 'pastTech.skills[0]：文字で');
  has(validateSkills({ other: {} }), 'skills.other：知らない項目');
});

test('プロジェクト：必須（id・kind・order・title）・期間・リンク・工程', () => {
  assert.deepEqual(validateProject(workProject), []);
  const errors = validateProject({});
  for (const part of ['.id：', '.kind：', '.order：', '.title：']) has(errors, part);
  has(validateProject({ ...workProject, id: 'あ' }), '.id：英数字');
  has(validateProject({ ...workProject, title: '  ' }), 'プロジェクト名を書いて');
  has(validateProject({ ...workProject, period: { start: '2023-13', end: null } }), 'period.start：YYYY-MM');
  has(validateProject({ ...workProject, period: { start: '2023-04', end: '現在' } }), 'period.end');
  has(validateProject({ ...workProject, period: { start: '2023-04', end: '2022-01' } }), '終わりが始まりより前');
  has(validateProject({ ...workProject, link: 'http://insecure.example.com' }), 'https://');
  has(validateProject({ ...workProject, workflow: { coding: true } }), 'workflow.coding：知らない項目');
  has(validateProject({ ...workProject, workflow: { basic_design: 'yes' } }), 'true か false');
  has(validateProject({ ...workProject, kind: 'private' }), 'Private には書きません');
  has(validateProject({ ...workProject, order: -1 }), '0 以上の整数');
  has(validateProject('x'), '「項目: 値」');
  assert.deepEqual(validateProject({ ...workProject, link: '' }), []);
});

test('プロジェクトの並び：並びでない・同じ id・多すぎる', () => {
  has(validateProjects({}), '並び');
  has(validateProjects([workProject, workProject]), '同じ id');
  const many = Array.from({ length: LIMITS.projects + 1 }, (_, i) => ({ ...workProject, id: `p${i}` }));
  has(validateProjects(many), `${LIMITS.projects} 件まで`);
});

test('表示設定：セクション・テーマ・表示の形・知らない項目', () => {
  has(validateDisplay({ sections: [{ id: 'home', visible: true }] }), 'about / skills / projects');
  has(validateDisplay({ sections: {} }), 'sections：並び');
  has(validateDisplay({ theme: 'blue' }), 'light / dark / system');
  has(validateDisplay({ projects: { view: 'grid' } }), 'list / collection');
  has(validateDisplay({ projects: { fields: { secret: true } } }), 'fields.secret：知らない項目');
  has(validateDisplay({ home: { tagline: 'no' } }), 'true か false');
  has(validateDisplay({ allowSheetDownload: 1 }), 'true か false');
  has(validateDisplay({ colors: {} }), 'display.colors：知らない項目');
});

test('編集データ全体：知らない項目・schemaVersion・大きすぎる', () => {
  has(validateDraftData({ extra: 1 }), 'data.extra：知らない項目');
  has(validateDraftData({ schemaVersion: 2 }), 'schemaVersion：1');
  has(validateDraftData([]), 'data：「項目: 値」');
  has(validateDraftData({ projects: 'x' }), 'data.projects：並び');
  const big = { profile: { about: Object.fromEntries(['intro', 'strengths', 'style', 'closing', 'recent', 'past'].map((k) => [k, 'あ'.repeat(5000)])) } };
  assert.deepEqual(validateDraftData(big), []);
  const huge = { projects: Array.from({ length: 200 }, (_, i) => ({ ...workProject, id: `p${i}`, details: 'あ'.repeat(4900) })) };
  has(validateDraftData(huge), '大きすぎます');
});
