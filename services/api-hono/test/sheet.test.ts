// test/sheet.test.ts … 見る人向けのスキルシート（Excel・PDF）：excel（FastAPI）の呼び出しと、その URL
import assert from 'node:assert/strict';
import { test } from 'node:test';

import { createApp } from '../src/app.ts';
import { TokenVerifier } from '../src/auth.ts';
import { ApiError } from '../src/errors.ts';
import { PortfolioService } from '../src/portfolio.ts';
import { excelRenderer, type SheetRenderer } from '../src/sheet.ts';
import { MemoryStore, PROJECT } from './helpers.ts';

const PDF = new TextEncoder().encode('%PDF-1.4 fake');

function setup(renderSheet?: SheetRenderer, allowSheetDownload: unknown = true) {
  const store = new MemoryStore();
  store.put('publicPages/sample', {
    data: { profile: { home: { name: '公開' } }, display: { allowSheetDownload } },
    version: 2,
    publishedAt: 'x',
  });
  const app = createApp({
    service: new PortfolioService(store),
    verifier: new TokenVerifier({ projectId: PROJECT, emulator: true }),
    log: () => {},
    renderSheet,
  });
  return app;
}

test('許していれば、公開ページのデータから作った PDF を返す（ダウンロード・短くキャッシュ）', async () => {
  const seen: unknown[][] = [];
  const app = setup(async (page, format) => {
    seen.push([page, format]);
    return PDF;
  });
  const res = await app.request('/api/public/sample/skill-sheet.pdf');
  assert.equal(res.status, 200);
  assert.equal(res.headers.get('content-type'), 'application/pdf');
  assert.equal(res.headers.get('content-disposition'), 'attachment; filename="skill-sheet-sample.pdf"');
  assert.equal(res.headers.get('cache-control'), 'public, max-age=300');
  assert.deepEqual(new Uint8Array(await res.arrayBuffer()), PDF);
  assert.equal((seen[0][0] as { version: number }).version, 2);
  assert.equal(seen[0][1], 'pdf');

  const xlsx = await app.request('/api/public/sample/skill-sheet.xlsx');
  assert.equal(xlsx.status, 200);
  assert.equal(xlsx.headers.get('content-type'), 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
  assert.equal(xlsx.headers.get('content-disposition'), 'attachment; filename="skill-sheet-sample.xlsx"');
  assert.equal(seen[1][1], 'xlsx');
  assert.equal((await app.request('/api/public/sample/skill-sheet.docx')).status, 404);
});

test('許していない・公開していない・名前の形が違うは 404（同じ形）', async () => {
  for (const allow of [false, null, 'true']) {
    const res = await setup(async () => PDF, allow).request('/api/public/sample/skill-sheet.pdf');
    assert.equal(res.status, 404, String(allow));
    assert.equal(((await res.json()) as { error: { code: string } }).error.code, 'not_found');
  }
  assert.equal((await setup(async () => PDF).request('/api/public/none/skill-sheet.pdf')).status, 404);
  assert.equal((await setup(async () => PDF).request('/api/public/A_B/skill-sheet.pdf')).status, 404);
});

test('excel の設定がなければ 503、excel が失敗したら 502', async () => {
  const none = await setup(undefined).request('/api/public/sample/skill-sheet.pdf');
  assert.equal(none.status, 503);
  assert.equal(((await none.json()) as { error: { code: string } }).error.code, 'not_configured');

  const failing = setup(async () => {
    throw new ApiError(502, 'upstream_error', 'x');
  });
  assert.equal((await failing.request('/api/public/sample/skill-sheet.pdf')).status, 502);
});

test('excelRenderer：データを JSON で送り、トークンを付け、バイト列を返す（PDF・Excel）', async () => {
  const calls: { url: string; init: RequestInit }[] = [];
  const render = excelRenderer({
    origin: 'http://excel:8001/',
    token: 'secret',
    fetch: (async (url: string, init: RequestInit) => {
      calls.push({ url, init });
      return new Response(PDF, { status: 200, headers: { 'Content-Type': 'application/pdf' } });
    }) as typeof fetch,
  });
  assert.deepEqual(await render({ data: { a: 1 }, version: 3 }, 'pdf'), PDF);
  assert.equal(calls[0].url, 'http://excel:8001/render/skill-sheet.pdf');
  assert.equal(calls[0].init.method, 'POST');
  assert.deepEqual(calls[0].init.headers, { 'Content-Type': 'application/json', 'X-Internal-Token': 'secret' });
  assert.deepEqual(JSON.parse(String(calls[0].init.body)), { data: { a: 1 } });

  // トークンなし・版なし
  const plain = excelRenderer({
    origin: 'http://excel:8001',
    fetch: (async (_url: string, init: RequestInit) => {
      calls.push({ url: _url, init });
      return new Response(PDF);
    }) as typeof fetch,
  });
  await plain({}, 'xlsx');
  assert.equal(calls[1].url, 'http://excel:8001/render/skill-sheet.xlsx');
  assert.deepEqual(calls[1].init.headers, { 'Content-Type': 'application/json' });
  assert.deepEqual(JSON.parse(String(calls[1].init.body)), { data: {} });
});

test('excelRenderer：失敗の答え・つながらない・時間切れは 502', async () => {
  const cases: (typeof fetch)[] = [
    (async () => new Response('{}', { status: 500 })) as typeof fetch,
    (async () => {
      throw new TypeError('fetch failed');
    }) as typeof fetch,
    // 答えが来ない（AbortSignal.timeout のタイマーはイベントループを止めないので、待つ間だけ別のタイマーで生かす）
    ((_url: string, init: RequestInit) =>
      new Promise((_resolve, reject) => {
        const keep = setTimeout(() => {}, 1_000);
        init.signal?.addEventListener('abort', () => {
          clearTimeout(keep);
          reject(init.signal?.reason);
        });
      })) as typeof fetch,
  ];
  for (const fetchFn of cases) {
    const render = excelRenderer({ origin: 'http://excel:8001', fetch: fetchFn, timeoutMs: 20 });
    await assert.rejects(render({ data: {} }, 'pdf'), (e: unknown) => e instanceof ApiError && e.status === 502);
  }
});
