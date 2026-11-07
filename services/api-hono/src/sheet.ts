// src/sheet.ts
//
// 公開ページを見る人向けのスキルシート（Excel・PDF）を、excel（services/excel-fastapi）に作らせる（docs/plan/excel.md・D-06）
// - 形は本人がダウンロードするものと同じ（Excel のテンプレート。PDF はその見た目のまま）
// - 送るのは公開ページのデータ（publicPages/{slug}。スキルシートだけの項目は入っていない）と版だけ
// - excel は Firestore につながない（D-05：Firestore は Hono だけ）。受け取ったデータから PDF を作って返すだけ
// - EXCEL_INTERNAL_TOKEN があれば X-Internal-Token に付ける（excel はほかから直接呼ばせない）
import { ApiError } from './errors.ts';

export type PublicPage = { data?: unknown; version?: unknown };

export type SheetFormat = 'pdf' | 'xlsx';

/** 公開ページ → スキルシートのバイト列 */
export type SheetRenderer = (page: PublicPage, format: SheetFormat) => Promise<Uint8Array<ArrayBuffer>>;

const upstreamError = () => new ApiError(502, 'upstream_error', 'スキルシートを作れませんでした。時間をおいてやり直してください');

export function excelRenderer({
  origin,
  token,
  fetch: fetchFn = fetch,
  timeoutMs = 20_000,
}: {
  origin: string;
  token?: string;
  fetch?: typeof fetch;
  timeoutMs?: number;
}): SheetRenderer {
  return async (page, format) => {
    let res: Response;
    try {
      res = await fetchFn(`${origin.replace(/\/$/, '')}/render/skill-sheet.${format}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', ...(token ? { 'X-Internal-Token': token } : {}) },
        body: JSON.stringify({ data: page.data ?? {} }),
        signal: AbortSignal.timeout(timeoutMs),
      });
    } catch {
      throw upstreamError(); // つながらない・時間切れ
    }
    if (!res.ok) throw upstreamError();
    return new Uint8Array(await res.arrayBuffer());
  };
}
