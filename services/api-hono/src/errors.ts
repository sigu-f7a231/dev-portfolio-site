// src/errors.ts
//
// API のエラー。ルート（app.ts）で {"error": {"code", "message"}} の JSON にする（前の backend と同じ形）

export class ApiError extends Error {
  readonly status: number;
  readonly code: string;
  /** 入力の誤りの一覧（「profile.home.name：文字で書いてください」など） */
  readonly details: string[];

  constructor(status: number, code: string, message: string, details: string[] = []) {
    super(message);
    this.status = status;
    this.code = code;
    this.details = details;
  }
}

/** 書き込みの前提（ほかの場所で先に変わっていない・まだない）が崩れた。Firestore の FAILED_PRECONDITION / ALREADY_EXISTS */
export class ConflictError extends Error {}

export const unauthorized = (message = 'ログインしてください') => new ApiError(401, 'unauthorized', message);
export const notFound = (message = '見つかりません') => new ApiError(404, 'not_found', message);
export const badRequest = (message: string, details: string[] = []) =>
  new ApiError(400, 'invalid_request', message, details);
export const conflict = (message = '別の場所で変更されました。読み込み直してください') =>
  new ApiError(409, 'conflict', message);
