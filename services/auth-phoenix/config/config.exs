import Config

# 認証サービスの設定（環境ごとの値は dev.exs / test.exs / prod.exs、起動時の環境変数は runtime.exs）
config :auth_service, AuthServiceWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter,
  url: [host: "localhost"],
  render_errors: [formats: [json: AuthServiceWeb.ErrorJSON], layout: false]

# Firebase Auth（runtime.exs で環境変数から上書きする）
config :auth_service, :firebase,
  project_id: "demo-dev-portfolio",
  api_key: "demo",
  auth_emulator_host: nil

# 登録できるメールアドレス（空なら誰でも。docs/plan/decisions.md の D-03）
config :auth_service, :signup_allowlist, []

# ブラウザから別のオリジンで呼ぶときに許すオリジン（nginx 経由なら要らない）
config :auth_service, :allowed_origin, nil

# ログインの失敗の数え方（総当たりの対策）：window_seconds の間に max_failures 回失敗したら、しばらく受け付けない
config :auth_service, :login_throttle, max_failures: 5, window_seconds: 900

# Firebase Auth の REST を呼ぶときに足すオプション（テストでは Req.Test に差し替える）
config :auth_service, :req_options, []

config :phoenix, :json_library, Jason
# リクエストのログは AuthServiceWeb.Plugs.RequestLog が JSON で書く（Phoenix の文字のログは出さない）
config :phoenix, :logger, false
config :logger, level: :info

import_config "#{config_env()}.exs"
