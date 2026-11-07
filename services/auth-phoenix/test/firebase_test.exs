defmodule AuthService.FirebaseTest do
  # Firebase Auth の REST の呼び方（つなぎ先・エラーの日本語）と、入力の確認・総当たりの対策
  use ExUnit.Case, async: false

  import AuthServiceWeb.FirebaseStub, only: [stub: 1, user: 1]

  alias AuthService.{Accounts, Error, Firebase, LoginThrottle}

  setup do
    original = Application.get_env(:auth_service, :firebase)
    on_exit(fn -> Application.put_env(:auth_service, :firebase, original) end)
    LoginThrottle.clear()
    :ok
  end

  describe "つなぎ先" do
    test "Emulator：http://<ホスト>/identitytoolkit.googleapis.com/v1/...、管理者は Bearer owner" do
      stub(%{"accounts:lookup" => user("u1")})
      assert {:ok, %{uid: "u1"}} = Firebase.lookup("tok")
      assert_received {:firebase, "accounts:lookup", %{scheme: :http, host: "auth.test", path: "/identitytoolkit.googleapis.com/v1/accounts:lookup"}}
      assert Firebase.emulator?()
      assert {:ok, "owner"} = AuthService.AccessToken.fetch()
    end

    test "本物：https://identitytoolkit.googleapis.com/v1/...、管理者はメタデータサーバーのトークン" do
      Application.put_env(:auth_service, :firebase, project_id: "real-project", api_key: "k", auth_emulator_host: nil)
      refute Firebase.emulator?()

      stub(%{"accounts:lookup" => user("u1"), "token" => %{"access_token" => "meta-token", "expires_in" => 3600}})
      assert {:ok, %{uid: "u1"}} = Firebase.lookup("tok")
      assert_received {:firebase, "accounts:lookup", %{scheme: :https, host: "identitytoolkit.googleapis.com", path: "/v1/accounts:lookup"}}

      assert {:ok, "meta-token"} = AuthService.AccessToken.fetch()
      assert_received {:firebase, "token", %{host: "metadata.google.internal", headers: %{"metadata-flavor" => "Google"}}}
    end

    test "demo- のプロジェクトで Emulator がなければ起動しない" do
      Application.put_env(:auth_service, :firebase, project_id: "demo-x", api_key: "k", auth_emulator_host: nil)
      assert_raise RuntimeError, ~r/FIREBASE_AUTH_EMULATOR_HOST/, &Firebase.check_config!/0
      Application.put_env(:auth_service, :firebase, project_id: "real", api_key: "k", auth_emulator_host: nil)
      assert Firebase.check_config!() == :ok
    end

    test "lookup：利用者がいない応答は 401" do
      stub(%{"accounts:lookup" => %{"kind" => "x"}})
      assert {:error, %Error{status: 401}} = Firebase.lookup("tok")
    end
  end

  test "Firebase のエラーの名前 → 日本語のエラー" do
    for {raw, status, code} <- [
          {"EMAIL_EXISTS", 409, "email_exists"},
          {"INVALID_LOGIN_CREDENTIALS", 401, "invalid_credentials"},
          {"EMAIL_NOT_FOUND", 401, "invalid_credentials"},
          {"USER_DISABLED", 401, "invalid_credentials"},
          {"TOO_MANY_ATTEMPTS_TRY_LATER : Access disabled", 429, "too_many_attempts"},
          {"WEAK_PASSWORD : Password should be at least 6 characters", 400, "weak_password"},
          {"INVALID_EMAIL", 400, "invalid_email"},
          {"MISSING_PASSWORD", 400, "invalid_request"},
          {"TOKEN_EXPIRED", 401, "unauthorized"},
          {"INVALID_REFRESH_TOKEN", 401, "unauthorized"},
          {"SOMETHING_NEW", 502, "upstream_error"}
        ] do
      assert %Error{status: ^status, code: ^code, message: message} = Error.from_firebase(raw)
      assert is_binary(message) and message != ""
    end

    assert %Error{status: 502} = Error.from_firebase(nil)
  end

  describe "入力の確認" do
    test "メールアドレス：前後の空白を取り、小文字にする。形・長さ" do
      assert Accounts.normalize_email("  A@Example.COM ") == {:ok, "a@example.com"}
      for bad <- ["", "a", "a@b", "a b@example.com", "@example.com", nil, 1, String.duplicate("a", 250) <> "@example.com"] do
        assert {:error, %Error{code: "invalid_email"}} = Accounts.normalize_email(bad)
      end
    end

    test "パスワード：8〜128 文字" do
      assert Accounts.check_password("12345678") == :ok
      assert Accounts.check_password(String.duplicate("あ", 128)) == :ok
      for bad <- ["1234567", String.duplicate("x", 129), nil, 12_345_678] do
        assert {:error, %Error{code: "weak_password"}} = Accounts.check_password(bad)
      end
    end
  end

  describe "総当たりの対策（LoginThrottle）" do
    test "決めた回数まで失敗すると止め、成功・時間で数え直す" do
      key = LoginThrottle.key("a@example.com", "1.2.3.4")
      assert LoginThrottle.check(key) == :ok
      for _ <- 1..3, do: LoginThrottle.record_failure(key)
      assert {:error, seconds} = LoginThrottle.check(key)
      assert seconds in 1..900
      LoginThrottle.reset(key)
      assert LoginThrottle.check(key) == :ok

      for _ <- 1..3, do: LoginThrottle.record_failure(key)
      original = Application.get_env(:auth_service, :login_throttle)
      Application.put_env(:auth_service, :login_throttle, max_failures: 3, window_seconds: 0)
      on_exit(fn -> Application.put_env(:auth_service, :login_throttle, original) end)
      assert LoginThrottle.check(key) == :ok, "時間が過ぎたら数え直す"
    end

    test "キーにメールアドレスをそのまま入れない" do
      key = LoginThrottle.key("secret@example.com", "1.2.3.4")
      refute key =~ "secret"
      assert byte_size(key) == 32
    end
  end
end
