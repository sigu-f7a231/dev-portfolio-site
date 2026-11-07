defmodule AuthServiceWeb.Plugs.RequestLog do
  @moduledoc """
  1 リクエスト 1 行の JSON ログ。Cloud Run では標準出力の JSON がそのまま Cloud Logging の構造化ログになる。
  メールアドレス・パスワード・トークンは書かない（パスとステータスだけ）。
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    started = System.monotonic_time(:microsecond)

    register_before_send(conn, fn conn ->
      seconds = (System.monotonic_time(:microsecond) - started) / 1_000_000

      severity =
        cond do
          conn.status >= 500 -> "ERROR"
          conn.status >= 400 -> "WARNING"
          true -> "INFO"
        end

      IO.puts(
        Jason.encode!(%{
          severity: severity,
          message: "#{conn.method} #{conn.request_path} #{conn.status}",
          httpRequest: %{
            requestMethod: conn.method,
            requestUrl: conn.request_path,
            status: conn.status,
            latency: :erlang.float_to_binary(seconds, decimals: 3) <> "s"
          }
        })
      )

      conn
    end)
  end
end
