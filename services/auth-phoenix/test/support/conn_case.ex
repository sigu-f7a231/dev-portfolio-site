defmodule AuthServiceWeb.ConnCase do
  @moduledoc "ルートのテスト（Phoenix.ConnTest）。Firebase は AuthServiceWeb.FirebaseStub、ログインの失敗の数はテストごとに消す"
  use ExUnit.CaseTemplate

  using do
    quote do
      import Plug.Conn
      import Phoenix.ConnTest
      import AuthServiceWeb.FirebaseStub, only: [stub: 1, error: 1, error: 2, session: 1, user: 1, user: 2]

      @endpoint AuthServiceWeb.Endpoint
    end
  end

  setup do
    AuthService.LoginThrottle.clear()
    {:ok, conn: Phoenix.ConnTest.build_conn() |> Plug.Conn.put_req_header("accept", "application/json")}
  end
end
