import Config

config :auth_service, AuthServiceWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: 4100],
  server: true,
  debug_errors: false,
  code_reloader: false,
  # 開発用（セッションは使わないので中身は何でもよい）
  secret_key_base: String.duplicate("dev-only-secret-", 4)
