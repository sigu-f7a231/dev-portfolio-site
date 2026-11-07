defmodule AuthService.EmulatorTest do
  # Auth Emulator の上で、登録からログアウト・退会までを通す（ふだんは飛ばす）
  #   docker compose up -d firebase（リポジトリの直下で）
  #   FIREBASE_AUTH_EMULATOR_HOST=localhost:9099 mix test --only emulator
  use AuthServiceWeb.ConnCase, async: false

  @moduletag :emulator

  setup_all do
    host = System.get_env("FIREBASE_AUTH_EMULATOR_HOST") || raise "FIREBASE_AUTH_EMULATOR_HOST を指定してください"
    firebase = Application.get_env(:auth_service, :firebase)
    req_options = Application.get_env(:auth_service, :req_options)

    Application.put_env(:auth_service, :firebase,
      project_id: System.get_env("FIREBASE_PROJECT") || "demo-dev-portfolio",
      api_key: "demo",
      auth_emulator_host: host
    )

    # 偽物（Req.Test）ではなく、本当に Emulator に送る
    Application.put_env(:auth_service, :req_options, retry: false)

    on_exit(fn ->
      Application.put_env(:auth_service, :firebase, firebase)
      Application.put_env(:auth_service, :req_options, req_options)
    end)

    :ok
  end

  defp bearer(token), do: build_conn() |> put_req_header("authorization", "Bearer #{token}")

  test "登録 → ログイン → 自分の情報 → 取り直し → パスワードの変更 → ログアウト → 再設定のメール → 退会" do
    email = "phoenix-#{System.unique_integer([:positive])}@example.com"

    signed_up = json_response(post(build_conn(), "/auth/signup", %{email: email, password: "first-password"}), 201)
    assert is_binary(signed_up["idToken"]) and is_binary(signed_up["refreshToken"])

    assert json_response(post(build_conn(), "/auth/login", %{email: email, password: "wrong-password"}), 401)
    logged_in = json_response(post(build_conn(), "/auth/login", %{email: email, password: "first-password"}), 200)
    assert logged_in["uid"] == signed_up["uid"]

    me = json_response(get(bearer(logged_in["idToken"]), "/auth/me"), 200)
    assert me["email"] == email

    refreshed = json_response(post(build_conn(), "/auth/refresh", %{refreshToken: logged_in["refreshToken"]}), 200)
    assert refreshed["uid"] == signed_up["uid"]

    changed =
      json_response(post(bearer(refreshed["idToken"]), "/auth/password/change", %{newPassword: "second-password"}), 200)

    assert json_response(post(build_conn(), "/auth/login", %{email: email, password: "second-password"}), 200)
    assert json_response(post(build_conn(), "/auth/login", %{email: email, password: "first-password"}), 401)

    assert response(post(bearer(changed["idToken"]), "/auth/logout", %{}), 204)
    assert response(post(build_conn(), "/auth/password/reset", %{email: email}), 204)

    final = json_response(post(build_conn(), "/auth/login", %{email: email, password: "second-password"}), 200)
    assert response(delete(bearer(final["idToken"]), "/auth/account"), 204)
    assert json_response(post(build_conn(), "/auth/login", %{email: email, password: "second-password"}), 401)
  end

  test "もう登録されているメールアドレスは 409" do
    email = "dup-#{System.unique_integer([:positive])}@example.com"
    first = json_response(post(build_conn(), "/auth/signup", %{email: email, password: "some-password"}), 201)
    assert json_response(post(build_conn(), "/auth/signup", %{email: email, password: "some-password"}), 409)
    assert response(delete(bearer(first["idToken"]), "/auth/account"), 204)
  end
end
