defmodule AuthServiceWeb.FirebaseStub do
  @moduledoc """
  Firebase Auth の REST の偽物（Req.Test）。テストごとに「呼ばれたら何を返すか」を決め、
  呼ばれた中身（本文・ヘッダー・クエリ・ホスト・パス）をテストのプロセスに `{:firebase, 名前, 中身}` で送る。

  名前は URL の最後（`accounts:signUp`・`token` など）。管理者としての呼び出し（`/projects/...`）は `admin:` を前に付ける。
  """

  import Plug.Conn

  def stub(routes) do
    test_pid = self()

    Req.Test.stub(AuthService.Firebase, fn conn ->
      {:ok, raw, conn} = read_body(conn)
      last = conn.request_path |> String.split("/") |> List.last()
      name = if String.contains?(conn.request_path, "/projects/"), do: "admin:" <> last, else: last

      send(test_pid, {:firebase, name,
       %{
         body: decode(conn, raw),
         headers: Map.new(conn.req_headers),
         query: conn.query_string,
         host: conn.host,
         scheme: conn.scheme,
         path: conn.request_path
       }})

      case Map.fetch(routes, name) do
        {:ok, fun} when is_function(fun, 0) -> respond(conn, fun.())
        {:ok, response} -> respond(conn, response)
        :error -> respond(conn, {404, %{"error" => %{"message" => "NOT_STUBBED"}}})
      end
    end)
  end

  defp decode(conn, raw) do
    case get_req_header(conn, "content-type") do
      ["application/x-www-form-urlencoded" <> _] -> URI.decode_query(raw)
      _ when raw == "" -> %{}
      _ -> Jason.decode!(raw)
    end
  end

  defp respond(conn, {status, body}) when is_map(body), do: conn |> put_status(status) |> Req.Test.json(body)
  defp respond(conn, {status, body}) when is_binary(body), do: send_resp(conn, status, body)
  defp respond(conn, body) when is_map(body), do: Req.Test.json(conn, body)

  @doc "Firebase のエラーの応答"
  def error(message, status \\ 400), do: {status, %{"error" => %{"code" => status, "message" => message}}}

  @doc "登録・ログインの応答"
  def session(uid),
    do: %{"localId" => uid, "idToken" => "id-#{uid}", "refreshToken" => "rt-#{uid}", "expiresIn" => "3600"}

  @doc "accounts:lookup の応答"
  def user(uid, email \\ "user@example.com"),
    do: %{"users" => [%{"localId" => uid, "email" => email, "emailVerified" => false}]}
end
