defmodule AuthServiceWeb.Router do
  @moduledoc """
  ルート（すべて JSON。エラーは `{"error": {"code", "message"}}`）

      GET    /healthz                … 動作確認
      POST   /auth/signup            … 登録 { email, password } → 201 { uid, idToken, refreshToken, expiresIn }（確認のメールを送る）
      POST   /auth/login             … ログイン { email, password } → { uid, idToken, refreshToken, expiresIn }
      POST   /auth/refresh           … 取り直し { refreshToken } → { uid, idToken, refreshToken, expiresIn }
      GET    /auth/me                … 自分の情報（Authorization: Bearer <ID トークン>）→ { uid, email, emailVerified }
      POST   /auth/logout            … すべての端末からログアウト（Bearer）→ 204
      POST   /auth/password/reset    … 再設定のメール { email } → 204（登録があるかどうかは返さない）
      POST   /auth/password/change   … パスワードの変更（Bearer）{ newPassword } → 新しいトークン
      DELETE /auth/account           … 退会（Bearer）→ 204
  """

  use Phoenix.Router
  import Phoenix.Controller

  pipeline :api do
    plug :accepts, ["json"]
  end

  get "/healthz", AuthServiceWeb.HealthController, :show

  scope "/auth", AuthServiceWeb do
    pipe_through :api

    post "/signup", AuthController, :sign_up
    post "/login", AuthController, :log_in
    post "/refresh", AuthController, :refresh
    get "/me", AuthController, :me
    post "/logout", AuthController, :log_out
    post "/password/reset", AuthController, :request_password_reset
    post "/password/change", AuthController, :change_password
    delete "/account", AuthController, :delete_account
  end
end
