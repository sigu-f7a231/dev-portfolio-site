import Config

# 起動時に環境変数から読む（テストのときは読まない。test.exs の値を使う）
#   PORT                         待ち受けるポート（既定 4100）
#   FIREBASE_PROJECT             Firebase のプロジェクト（既定 demo-dev-portfolio。demo- で始まる名前は Emulator だけ）
#   FIREBASE_API_KEY             Firebase の Web API キー（本物のとき。Emulator は何でもよい）
#   FIREBASE_AUTH_EMULATOR_HOST  あれば Auth Emulator につなぐ（例 firebase:9099）
#   SIGNUP_ALLOWLIST             登録できるメールアドレス（カンマ区切り。空なら誰でも）
#   ALLOWED_ORIGIN               ブラウザから別のオリジンで呼ぶときに許すオリジン
#   SECRET_KEY_BASE              本番の Phoenix の秘密（セッションは使わないが、あれば使う）
if config_env() != :test do
  port = String.to_integer(System.get_env("PORT") || "4100")
  config :auth_service, AuthServiceWeb.Endpoint, http: [ip: {0, 0, 0, 0}, port: port]

  emulator_host =
    case System.get_env("FIREBASE_AUTH_EMULATOR_HOST") do
      nil -> nil
      "" -> nil
      host -> host
    end

  config :auth_service, :firebase,
    project_id: System.get_env("FIREBASE_PROJECT") || "demo-dev-portfolio",
    api_key: System.get_env("FIREBASE_API_KEY") || "demo",
    auth_emulator_host: emulator_host

  allowlist =
    (System.get_env("SIGNUP_ALLOWLIST") || "")
    |> String.split(",", trim: true)
    |> Enum.map(&(&1 |> String.trim() |> String.downcase()))
    |> Enum.reject(&(&1 == ""))

  config :auth_service, :signup_allowlist, allowlist

  config :auth_service, :allowed_origin, System.get_env("ALLOWED_ORIGIN")
end

if config_env() == :prod do
  config :auth_service, AuthServiceWeb.Endpoint,
    secret_key_base:
      System.get_env("SECRET_KEY_BASE") || Base.encode64(:crypto.strong_rand_bytes(48))
end
