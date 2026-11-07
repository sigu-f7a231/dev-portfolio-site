defmodule AuthServiceWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :auth_service

  # 1 リクエスト 1 行の JSON ログ（Cloud Logging の構造化ログ）。メールアドレスなどは書かない
  plug AuthServiceWeb.Plugs.RequestLog
  # ブラウザから別のオリジンで呼ぶとき（ALLOWED_ORIGIN）だけ
  plug AuthServiceWeb.Plugs.Cors

  # JSON を読む。読めなければ 400・大きすぎれば 413・JSON でなければ 415（同じ形の JSON で答える）
  plug AuthServiceWeb.Plugs.JsonBody,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason,
    length: 64_000

  plug AuthServiceWeb.Router
end
