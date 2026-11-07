defmodule AuthServiceWeb.Plugs.JsonBody do
  @moduledoc """
  受け取った JSON を読む（Plug.Parsers を包む）

  読めない・大きすぎる・Content-Type が違うときは、例外を投げずに、ほかのエラーと同じ形の JSON で答える
  （{"error": {"code", "message"}}。中身は AuthServiceWeb.ErrorJSON）
  """
  @behaviour Plug

  import Plug.Conn

  @impl true
  def init(opts), do: Plug.Parsers.init(opts)

  @impl true
  def call(conn, parsers) do
    Plug.Parsers.call(conn, parsers)
  rescue
    Plug.Parsers.ParseError -> reply(conn, 400)
    Plug.Parsers.RequestTooLargeError -> reply(conn, 413)
    Plug.Parsers.UnsupportedMediaTypeError -> reply(conn, 415)
  end

  defp reply(conn, status) do
    body = AuthServiceWeb.ErrorJSON.render("#{status}.json", %{})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(body))
    |> halt()
  end
end
