defmodule AuthServiceWeb.AuthControllerTest do
  # ルートのテスト。Firebase Auth は偽物（Req.Test）に差し替え、送った中身と返す JSON を確かめる
  use AuthServiceWeb.ConnCase, async: false

  import ExUnit.CaptureIO

  alias AuthService.LoginThrottle

  @password "password123"

  defp error_code(conn, status), do: json_response(conn, status)["error"]["code"]
  defp with_token(conn, token \\ "id-u1"), do: put_req_header(conn, "authorization", "Bearer #{token}")

  test "GET /healthz は 200、キャッシュさせない", %{conn: conn} do
    conn = get(conn, "/healthz")
    assert json_response(conn, 200) == %{"status" => "ok"}
    assert get_resp_header(conn, "cache-control") == ["no-store"]
  end

  describe "登録（POST /auth/signup）" do
    test "メールアドレスを整えて Firebase に登録し、確認のメールを送り、トークンを返す", %{conn: conn} do
      stub(%{"accounts:signUp" => session("u1"), "accounts:sendOobCode" => %{"email" => "user@example.com"}})
      conn = post(conn, "/auth/signup", %{email: "  User@Example.com ", password: @password})

      assert json_response(conn, 201) == %{"uid" => "u1", "idToken" => "id-u1", "refreshToken" => "rt-u1", "expiresIn" => 3600}

      assert_received {:firebase, "accounts:signUp",
                       %{body: %{"email" => "user@example.com", "password" => @password, "returnSecureToken" => true}} = req}

      assert req.query =~ "key=test-key"
      assert req.host == "auth.test"
      assert req.path == "/identitytoolkit.googleapis.com/v1/accounts:signUp"
      assert_received {:firebase, "accounts:sendOobCode", %{body: %{"requestType" => "VERIFY_EMAIL", "idToken" => "id-u1"}}}
    end

    test "確認のメールを送れなくても、登録は成功", %{conn: conn} do
      stub(%{"accounts:signUp" => session("u1"), "accounts:sendOobCode" => error("TOO_MANY_ATTEMPTS_TRY_LATER")})
      assert json_response(post(conn, "/auth/signup", %{email: "a@example.com", password: @password}), 201)
    end

    test "異常系：メールアドレスの形・短いパスワード・入れていない（Firebase には送らない）", %{conn: conn} do
      stub(%{})
      assert error_code(post(conn, "/auth/signup", %{email: "not-an-email", password: @password}), 400) == "invalid_email"
      assert error_code(post(conn, "/auth/signup", %{email: "a@example.com", password: "short"}), 400) == "weak_password"
      assert error_code(post(conn, "/auth/signup", %{email: "a@example.com", password: String.duplicate("x", 129)}), 400) == "weak_password"
      assert error_code(post(conn, "/auth/signup", %{}), 400) == "invalid_email"
      assert error_code(post(conn, "/auth/signup", %{email: "a@example.com"}), 400) == "weak_password"
      refute_received {:firebase, _, _}
    end

    test "異常系：もう登録されている（409）・Firebase が弱いと言った（400）", %{conn: conn} do
      stub(%{"accounts:signUp" => error("EMAIL_EXISTS")})
      assert error_code(post(conn, "/auth/signup", %{email: "a@example.com", password: @password}), 409) == "email_exists"
      stub(%{"accounts:signUp" => error("WEAK_PASSWORD : Password should be at least 6 characters")})
      assert error_code(post(build_conn(), "/auth/signup", %{email: "a@example.com", password: @password}), 400) == "weak_password"
    end

    test "登録できる人を決めているときは、それ以外は 403（Firebase には送らない）", %{conn: conn} do
      Application.put_env(:auth_service, :signup_allowlist, ["ok@example.com"])
      on_exit(fn -> Application.put_env(:auth_service, :signup_allowlist, []) end)
      stub(%{"accounts:signUp" => session("ok"), "accounts:sendOobCode" => %{}})

      assert error_code(post(conn, "/auth/signup", %{email: "other@example.com", password: @password}), 403) == "signup_not_allowed"
      refute_received {:firebase, "accounts:signUp", _}
      assert json_response(post(build_conn(), "/auth/signup", %{email: "OK@example.com", password: @password}), 201)
    end
  end

  describe "ログイン（POST /auth/login）" do
    test "正しければトークンを返す", %{conn: conn} do
      stub(%{"accounts:signInWithPassword" => session("u1")})
      conn = post(conn, "/auth/login", %{email: "User@Example.com", password: @password})
      assert json_response(conn, 200)["idToken"] == "id-u1"
      assert_received {:firebase, "accounts:signInWithPassword", %{body: %{"email" => "user@example.com"}}}
    end

    test "メールアドレスがない・パスワードが違うは、同じ 401（どちらかを教えない）", %{conn: conn} do
      for message <- ["EMAIL_NOT_FOUND", "INVALID_PASSWORD", "INVALID_LOGIN_CREDENTIALS"] do
        stub(%{"accounts:signInWithPassword" => error(message)})
        body = json_response(post(build_conn(), "/auth/login", %{email: "a@example.com", password: @password}), 401)
        assert body["error"] == %{"code" => "invalid_credentials", "message" => "メールアドレスかパスワードが違います"}
      end

      assert error_code(post(conn, "/auth/login", %{email: "a@example.com"}), 400) == "invalid_request"
    end

    test "続けて失敗したら 429（Retry-After 付き）。その間は Firebase に問い合わせない。ほかの接続元は別に数える", %{conn: conn} do
      stub(%{"accounts:signInWithPassword" => error("INVALID_PASSWORD")})
      login = fn ip -> build_conn() |> put_req_header("x-forwarded-for", ip) |> post("/auth/login", %{email: "a@example.com", password: "wrong-password"}) end

      for _ <- 1..3, do: assert(json_response(login.("10.0.0.1"), 401))
      # 3 回の問い合わせを読み捨てる
      for _ <- 1..3, do: assert_received({:firebase, "accounts:signInWithPassword", _})

      conn429 = login.("10.0.0.1")
      assert error_code(conn429, 429) == "too_many_attempts"
      assert [seconds] = get_resp_header(conn429, "retry-after")
      assert String.to_integer(seconds) > 0
      refute_received {:firebase, _, _}

      assert json_response(login.("10.0.0.2"), 401), "ほかの接続元は止めない"
      _ = conn
    end

    test "成功したら数え直す", %{conn: conn} do
      stub(%{"accounts:signInWithPassword" => error("INVALID_PASSWORD")})
      for _ <- 1..2, do: post(build_conn(), "/auth/login", %{email: "a@example.com", password: "wrong-password"})
      stub(%{"accounts:signInWithPassword" => session("u1")})
      assert json_response(post(conn, "/auth/login", %{email: "a@example.com", password: @password}), 200)
      assert LoginThrottle.check(LoginThrottle.key("a@example.com", "127.0.0.1")) == :ok
    end
  end

  describe "取り直し（POST /auth/refresh）" do
    test "更新用のトークンで新しいトークンを返す（Secure Token にフォームで送る）", %{conn: conn} do
      stub(%{"token" => %{"id_token" => "new-id", "refresh_token" => "new-rt", "expires_in" => "3600", "user_id" => "u1"}})
      conn = post(conn, "/auth/refresh", %{refreshToken: "rt-u1"})
      assert json_response(conn, 200) == %{"uid" => "u1", "idToken" => "new-id", "refreshToken" => "new-rt", "expiresIn" => 3600}

      assert_received {:firebase, "token",
                       %{body: %{"grant_type" => "refresh_token", "refresh_token" => "rt-u1"}, path: "/securetoken.googleapis.com/v1/token"}}
    end

    test "異常系：送っていない（400）・使えない（401）", %{conn: conn} do
      stub(%{"token" => error("INVALID_REFRESH_TOKEN")})
      assert error_code(post(conn, "/auth/refresh", %{}), 400) == "invalid_request"
      assert error_code(post(build_conn(), "/auth/refresh", %{refreshToken: "bad"}), 401) == "unauthorized"
    end
  end

  describe "ログインが要るもの（Authorization: Bearer <ID トークン>）" do
    test "トークンがなければ 401（Firebase には送らない）", %{conn: conn} do
      stub(%{})
      assert error_code(get(conn, "/auth/me"), 401) == "unauthorized"
      assert error_code(post(build_conn(), "/auth/logout", %{}), 401) == "unauthorized"
      assert error_code(post(build_conn(), "/auth/password/change", %{newPassword: @password}), 401) == "unauthorized"
      assert error_code(delete(build_conn(), "/auth/account"), 401) == "unauthorized"
      refute_received {:firebase, _, _}
    end

    test "自分の情報：Firebase が確かめた uid とメールアドレス。使えないトークンは 401", %{conn: conn} do
      stub(%{"accounts:lookup" => user("u1", "me@example.com")})
      assert json_response(get(with_token(conn), "/auth/me"), 200) == %{"uid" => "u1", "email" => "me@example.com", "emailVerified" => false}
      assert_received {:firebase, "accounts:lookup", %{body: %{"idToken" => "id-u1"}}}

      stub(%{"accounts:lookup" => error("INVALID_ID_TOKEN")})
      assert error_code(get(with_token(build_conn(), "bad"), "/auth/me"), 401) == "unauthorized"
    end

    test "ログアウト：管理者として、その人の更新用のトークンをすべて使えなくする（204）", %{conn: conn} do
      stub(%{"accounts:lookup" => user("u1"), "admin:accounts:update" => %{"localId" => "u1"}})
      assert response(post(with_token(conn), "/auth/logout", %{}), 204) == ""

      assert_received {:firebase, "admin:accounts:update", %{body: %{"localId" => "u1", "validSince" => since}, headers: headers, path: path}}
      assert headers["authorization"] == "Bearer owner"
      assert path == "/identitytoolkit.googleapis.com/v1/projects/demo-test/accounts:update"
      assert String.to_integer(since) > 0
    end

    test "パスワードの変更：短ければ 400（Firebase に送らない）、正しければ新しいトークン", %{conn: conn} do
      stub(%{"accounts:lookup" => user("u1"), "accounts:update" => session("u1")})
      assert error_code(post(with_token(conn), "/auth/password/change", %{newPassword: "short"}), 400) == "weak_password"
      refute_received {:firebase, _, _}

      body = json_response(post(with_token(build_conn()), "/auth/password/change", %{newPassword: "new-password-1"}), 200)
      assert body["idToken"] == "id-u1"
      assert_received {:firebase, "accounts:update", %{body: %{"idToken" => "id-u1", "password" => "new-password-1"}}}
    end

    test "退会：アカウントを消す（204）", %{conn: conn} do
      stub(%{"accounts:lookup" => user("u1"), "accounts:delete" => %{}})
      assert response(delete(with_token(conn), "/auth/account"), 204) == ""
      assert_received {:firebase, "accounts:delete", %{body: %{"idToken" => "id-u1"}}}
    end
  end

  describe "パスワードの再設定（POST /auth/password/reset）" do
    test "登録があってもなくても 204（あるかどうかを教えない）", %{conn: conn} do
      stub(%{"accounts:sendOobCode" => error("EMAIL_NOT_FOUND")})
      assert response(post(conn, "/auth/password/reset", %{email: "nobody@example.com"}), 204) == ""
      assert_received {:firebase, "accounts:sendOobCode", %{body: %{"requestType" => "PASSWORD_RESET", "email" => "nobody@example.com"}}}
      assert error_code(post(build_conn(), "/auth/password/reset", %{email: "bad"}), 400) == "invalid_email"
    end
  end

  describe "エラーの形" do
    test "Firebase が JSON でない 500・知らないエラーは 502", %{conn: conn} do
      stub(%{"accounts:signInWithPassword" => {500, "<html>boom</html>"}})
      assert error_code(post(conn, "/auth/login", %{email: "a@example.com", password: @password}), 502) == "upstream_error"
      stub(%{"accounts:signInWithPassword" => error("SOMETHING_NEW")})
      assert error_code(post(build_conn(), "/auth/login", %{email: "a@example.com", password: @password}), 502) == "upstream_error"
    end

    test "ないパスは 404、JSON が読めなければ 400・大きすぎれば 413・JSON でなければ 415（同じ形の JSON）" do
      conn = get(build_conn(), "/auth/nope")
      assert json_response(conn, 404)["error"]["code"] == "not_found"

      # JSON を読むところ（Plugs.JsonBody）が、例外を投げずに答える
      conn = build_conn() |> put_req_header("content-type", "application/json") |> post("/auth/login", "{bad json")
      assert json_response(conn, 400)["error"]["code"] == "invalid_request"

      big = Jason.encode!(%{email: String.duplicate("a", 70_000)})
      conn = build_conn() |> put_req_header("content-type", "application/json") |> post("/auth/login", big)
      assert json_response(conn, 413)["error"]["code"] == "too_large"

      conn = build_conn() |> put_req_header("content-type", "text/xml") |> post("/auth/login", "<a/>")
      assert json_response(conn, 415)["error"]["code"] == "unsupported_media_type"
    end
  end

  test "ログ：1 リクエスト 1 行の JSON。メールアドレス・パスワード・トークンは書かない", %{conn: conn} do
    stub(%{"accounts:signInWithPassword" => session("secret-uid")})

    output =
      capture_io(fn ->
        post(conn, "/auth/login", %{email: "secret@example.com", password: "secret-password"})
      end)

    [line] = output |> String.split("\n", trim: true)
    log = Jason.decode!(line)
    assert log["severity"] == "INFO"
    assert log["httpRequest"]["status"] == 200
    assert log["message"] == "POST /auth/login 200"
    for secret <- ["secret@example.com", "secret-password", "id-secret-uid", "rt-secret-uid"], do: refute(output =~ secret)
  end

  describe "CORS（ALLOWED_ORIGIN）" do
    setup do
      Application.put_env(:auth_service, :allowed_origin, "http://localhost:5000")
      on_exit(fn -> Application.put_env(:auth_service, :allowed_origin, nil) end)
    end

    test "許したオリジンの事前確認には 204 とヘッダー、ほかのオリジンには付けない" do
      conn = build_conn() |> put_req_header("origin", "http://localhost:5000") |> options("/auth/login")
      assert conn.status == 204
      assert get_resp_header(conn, "access-control-allow-origin") == ["http://localhost:5000"]
      assert get_resp_header(conn, "access-control-allow-headers") == ["Authorization, Content-Type"]

      stub(%{})
      other = build_conn() |> put_req_header("origin", "http://evil.example.com") |> get("/healthz")
      assert get_resp_header(other, "access-control-allow-origin") == []
    end
  end
end
