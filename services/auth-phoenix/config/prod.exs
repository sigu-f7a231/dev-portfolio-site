import Config

# 起動時の値（ポート・Firebase・許すオリジン）は runtime.exs で環境変数から
config :auth_service, AuthServiceWeb.Endpoint, server: true
