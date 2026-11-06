// test/portfolio.test.ts … 本人のデータの読み書き（メモリ上の偽物の Firestore で）
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { ApiError } from '../src/errors.ts';
import { PortfolioService, emptyDraftData } from '../src/portfolio.ts';
import { MemoryStore, workProject } from './helpers.ts';

const NOW = new Date('2026-11-06T07:00:00.000Z');

function setup() {
  const store = new MemoryStore();
  let id = 0;
  const service = new PortfolioService(store, { now: () => NOW, newId: () => `p_new_${++id}` });
  return { store, service };
}

async function rejectsWith(p: Promise<unknown>, status: number, code?: string) {
  await assert.rejects(p, (e: unknown) => e instanceof ApiError && e.status === status && (!code || e.code === code));
}

test('はじめて：編集データは空、updatedAt は null', async () => {
  const { service } = setup();
  assert.deepEqual(await service.getDraft('a'), { data: emptyDraftData(), updatedAt: null });
  assert.deepEqual(await service.getSection('a', 'profile'), {});
  assert.deepEqual(await service.listProjects('a'), []);
});

test('全体を保存：本人の文書だけに書き、本人の情報（users/{uid}）もはじめてなら作る', async () => {
  const { store, service } = setup();
  const data = { ...emptyDraftData(), profile: { home: { name: '本人' } } };
  const saved = await service.saveDraft('a', data, null);
  assert.equal(saved.updatedAt, NOW.toISOString());
  assert.deepEqual([...store.docs.keys()].sort(), ['users/a', 'users/a/drafts/current']);
  assert.equal(store.docs.get('users/a')!.data.latestVersion, 0);
  assert.equal(store.docs.get('users/a')!.data.slug, null);
  assert.deepEqual((await service.getDraft('a')).data.profile, { home: { name: '本人' } });
  assert.deepEqual(await service.getDraft('b'), { data: emptyDraftData(), updatedAt: null }, 'ほかの人には見えない');
});

test('全体を保存：読んだときの updatedAt と違えば 409（別のタブ・端末で先に変わった）', async () => {
  const { service } = setup();
  const first = await service.saveDraft('a', emptyDraftData(), null);
  await rejectsWith(service.saveDraft('a', emptyDraftData(), null), 409, 'conflict');
  await rejectsWith(service.saveDraft('a', emptyDraftData(), '2000-01-01T00:00:00.000Z'), 409);
  const second = await service.saveDraft('a', { ...emptyDraftData(), display: { theme: 'dark' } }, first.updatedAt);
  assert.equal(second.data.display.theme, 'dark');
});

test('全体を保存：読んでから書くまでの間に変わったら 409', async () => {
  const { store, service } = setup();
  await service.saveDraft('a', emptyDraftData(), null);
  store.beforeCommit = () => store.put('users/a/drafts/current', { data: emptyDraftData(), updatedAt: NOW.toISOString() });
  await rejectsWith(service.saveDraft('a', emptyDraftData(), NOW.toISOString()), 409);
});

test('全体を保存：形が違えば 400 と誤りの一覧、何も書かない', async () => {
  const { store, service } = setup();
  await assert.rejects(service.saveDraft('a', { profile: { home: { name: 1 } } }, null), (e: unknown) => {
    assert.ok(e instanceof ApiError);
    assert.equal(e.status, 400);
    assert.ok(e.details.some((d) => d.includes('data.profile.home.name')));
    return true;
  });
  assert.equal(store.docs.size, 0);
});

test('まとまりごと：プロフィール・スキル・表示設定を置き換え、ほかのまとまりは残る', async () => {
  const { service } = setup();
  await service.putSection('a', 'profile', { home: { name: 'A' } });
  await service.putSection('a', 'skills', { recentTech: { skills: ['Dart'] } });
  await service.putSection('a', 'display', { theme: 'dark' });
  const draft = await service.getDraft('a');
  assert.deepEqual(draft.data.profile, { home: { name: 'A' } });
  assert.deepEqual(draft.data.skills, { recentTech: { skills: ['Dart'] } });
  assert.deepEqual(draft.data.display, { theme: 'dark' });
  await rejectsWith(service.putSection('a', 'display', { theme: 'blue' }), 400);
  await rejectsWith(service.putSection('a', 'profile', undefined), 400);
});

test('まとまりごと：ほかの場所と重なったらやり直し、ほかのまとまりを消さない。3 回だめなら 409', async () => {
  const { store, service } = setup();
  await service.putSection('a', 'profile', { home: { name: 'A' } });
  // 1 回目の書き込みの直前に、ほかの場所がスキルを書いた
  store.beforeCommit = () => {
    const current = store.docs.get('users/a/drafts/current')!.data;
    store.put('users/a/drafts/current', {
      ...current,
      data: { ...(current.data as object), skills: { pastTech: { skills: ['Go'] } } },
    });
  };
  await service.putSection('a', 'display', { theme: 'dark' });
  const draft = await service.getDraft('a');
  assert.deepEqual(draft.data.skills, { pastTech: { skills: ['Go'] } }, 'ほかの場所の変更が残る');
  assert.deepEqual(draft.data.display, { theme: 'dark' });

  // 毎回重なる
  const always = new MemoryStore();
  const s2 = new PortfolioService(always, { now: () => NOW });
  await s2.putSection('a', 'profile', {});
  const original = always.commit.bind(always);
  always.commit = async (writes) => {
    always.put('users/a/drafts/current', always.docs.get('users/a/drafts/current')!.data);
    return original(writes);
  };
  await rejectsWith(s2.putSection('a', 'profile', { home: { name: 'x' } }), 409);
});

test('職務経歴：足す（id・order を作る）・置き換える・消す', async () => {
  const { service } = setup();
  const { id: _id, order: _order, ...noId } = workProject;
  const a = await service.addProject('a', noId);
  assert.equal(a.id, 'p_new_1');
  assert.equal(a.order, 0);
  const b = await service.addProject('a', { ...noId, title: '2 件目' });
  assert.equal(b.order, 1);
  const p = await service.addProject('a', { id: 'priv', kind: 'private', title: '個人' });
  assert.equal(p.order, 0, 'Private は Private の中での順番');

  const updated = await service.updateProject('a', 'p_new_1', { ...noId, order: 0, title: '変えた', id: 'ignored' });
  assert.equal(updated.id, 'p_new_1', 'id は変えられない');
  assert.equal((await service.listProjects('a')).find((x) => x.id === 'p_new_1')!.title, '変えた');

  await service.deleteProject('a', 'p_new_2');
  assert.deepEqual((await service.listProjects('a')).map((x) => x.id), ['p_new_1', 'priv']);
});

test('職務経歴の異常系：ない id・同じ id・形の誤り・ほかの人の案件は見えない', async () => {
  const { service } = setup();
  await service.addProject('a', workProject);
  await rejectsWith(service.addProject('a', workProject), 409, 'duplicate_id');
  await rejectsWith(service.addProject('a', { ...workProject, id: 'x', title: '' }), 400);
  await rejectsWith(service.addProject('a', ['x']), 400);
  await rejectsWith(service.updateProject('a', 'nope', workProject), 404);
  await rejectsWith(service.updateProject('a', workProject.id, null), 400);
  await rejectsWith(service.deleteProject('a', 'nope'), 404);
  await rejectsWith(service.updateProject('b', workProject.id, workProject), 404, 'not_found');
  await rejectsWith(service.deleteProject('b', workProject.id), 404);
});

test('公開ページ：あれば返し、ない・名前の形が違うは同じ 404', async () => {
  const { store, service } = setup();
  store.put('publicPages/sample', { data: { profile: {} }, version: 1, publishedAt: NOW.toISOString() });
  assert.deepEqual(await service.getPublicPage('sample'), { data: { profile: {} }, version: 1, publishedAt: NOW.toISOString() });
  await rejectsWith(service.getPublicPage('none'), 404, 'not_found');
  await rejectsWith(service.getPublicPage('../users/a'), 404, 'not_found');
});
