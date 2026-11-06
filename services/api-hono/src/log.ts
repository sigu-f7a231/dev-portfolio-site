// src/log.ts
//
// 1 行 1 件の JSON のログ。Cloud Run では標準出力の JSON がそのまま Cloud Logging の構造化ログになる
// （severity・httpRequest を読む）。個人の情報（メールアドレス・プロフィールの中身・uid）は書かない

export type Severity = 'DEBUG' | 'INFO' | 'WARNING' | 'ERROR';

export type LogWriter = (line: string) => void;

export function logEntry(write: LogWriter, severity: Severity, message: string, extra: Record<string, unknown> = {}) {
  write(JSON.stringify({ severity, message, ...extra }));
}

/** リクエスト 1 件のログ */
export function logRequest(
  write: LogWriter,
  req: { method: string; path: string; status: number; latencyMs: number },
) {
  const severity: Severity = req.status >= 500 ? 'ERROR' : req.status >= 400 ? 'WARNING' : 'INFO';
  logEntry(write, severity, `${req.method} ${req.path} ${req.status}`, {
    httpRequest: {
      requestMethod: req.method,
      requestUrl: req.path,
      status: req.status,
      latency: `${(req.latencyMs / 1000).toFixed(3)}s`,
    },
  });
}
