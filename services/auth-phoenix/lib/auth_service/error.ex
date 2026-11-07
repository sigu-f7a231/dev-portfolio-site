defmodule AuthService.Error do
  @moduledoc """
  認証のエラー。ルートで `{"error": {"code", "message"}}` の JSON にする（API（Hono）と同じ形）。

  Firebase Auth のエラーの名前（`EMAIL_EXISTS` など）を、画面に出せる日本語にする。
  ログインの失敗は、メールアドレスがないのかパスワードが違うのかを区別しない（どちらがあるかを教えないため）。
  """

  defexception [:status, :code, :message, retry_after: nil]

  @type t :: %__MODULE__{status: pos_integer(), code: String.t(), message: String.t(), retry_after: nil | pos_integer()}

  def new(status, code, message, retry_after \\ nil),
    do: %__MODULE__{status: status, code: code, message: message, retry_after: retry_after}

  def unauthorized, do: new(401, "unauthorized", "ログインし直してください")
  def bad_request(message), do: new(400, "invalid_request", message)

  @invalid_credentials ~w(INVALID_LOGIN_CREDENTIALS EMAIL_NOT_FOUND INVALID_PASSWORD USER_DISABLED)
  @needs_login ~w(INVALID_ID_TOKEN TOKEN_EXPIRED USER_NOT_FOUND INVALID_REFRESH_TOKEN CREDENTIAL_TOO_OLD_LOGIN_AGAIN)

  @doc "Firebase Auth の REST のエラー（`message` は `WEAK_PASSWORD : ...` のような形）"
  def from_firebase(raw) when is_binary(raw) do
    case raw |> String.split([" ", ":"], parts: 2) |> hd() do
      "EMAIL_EXISTS" -> new(409, "email_exists", "このメールアドレスはもう登録されています")
      code when code in @invalid_credentials -> new(401, "invalid_credentials", "メールアドレスかパスワードが違います")
      "TOO_MANY_ATTEMPTS_TRY_LATER" -> new(429, "too_many_attempts", "しばらくしてからお試しください")
      "WEAK_PASSWORD" -> new(400, "weak_password", "パスワードが短すぎます")
      "INVALID_EMAIL" -> new(400, "invalid_email", "メールアドレスの形が正しくありません")
      "MISSING_PASSWORD" -> bad_request("パスワードを入れてください")
      code when code in @needs_login -> unauthorized()
      _ -> upstream()
    end
  end

  def from_firebase(_), do: upstream()

  def upstream, do: new(502, "upstream_error", "認証サービスでエラーが起きました。しばらくしてからお試しください")
  def unavailable, do: new(503, "unavailable", "認証サービスにつながりません。しばらくしてからお試しください")
end
