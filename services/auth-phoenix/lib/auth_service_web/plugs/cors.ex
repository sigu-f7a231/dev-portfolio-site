defmodule AuthServiceWeb.Plugs.Cors do
  @moduledoc """
  ブラウザから別のオリジンで呼ぶとき（`ALLOWED_ORIGIN`。`flutter run --web-port 5000` なら `http://localhost:5000`）だけ、
  そのオリジンを許す。nginx（http://localhost:8000/auth/）を通すなら要らない。
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    allowed = Application.get_env(:auth_service, :allowed_origin)

    case get_req_header(conn, "origin") do
      [^allowed] when is_binary(allowed) and allowed != "" ->
        conn =
          conn
          |> put_resp_header("access-control-allow-origin", allowed)
          |> put_resp_header("vary", "Origin")

        if conn.method == "OPTIONS" do
          conn
          |> put_resp_header("access-control-allow-methods", "GET, POST, DELETE, OPTIONS")
          |> put_resp_header("access-control-allow-headers", "Authorization, Content-Type")
          |> put_resp_header("access-control-max-age", "600")
          |> send_resp(204, "")
          |> halt()
        else
          conn
        end

      _ ->
        conn
    end
  end
end
