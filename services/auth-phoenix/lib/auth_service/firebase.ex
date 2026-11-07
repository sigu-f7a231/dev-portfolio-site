defmodule AuthService.Firebase do
  @moduledoc """
  Firebase Auth の REST（Identity Toolkit・Secure Token）を呼ぶ。パスワードは Firebase が持つ（ここには残さない）。

  - 本物：`https://identitytoolkit.googleapis.com/v1`・`https://securetoken.googleapis.com/v1`（Web API キーを付ける）
  - Emulator（`FIREBASE_AUTH_EMULATOR_HOST` があるとき）：`http://<ホスト>/identitytoolkit.googleapis.com/v1` など
  - 管理者としての呼び出し（すべての端末からのログアウト）：Emulator は `Bearer owner`、本物はサービスアカウントのアクセストークン
  - テストでは `config :auth_service, :req_options, plug: {Req.Test, AuthService.Firebase}` で差し替える

  https://cloud.google.com/identity-platform/docs/reference/rest/v1/accounts
  """

  alias AuthService.Error

  @type session :: %{uid: String.t(), id_token: String.t(), refresh_token: String.t(), expires_in: pos_integer()}
  @type user :: %{uid: String.t(), email: String.t() | nil, email_verified: boolean()}

  def config, do: Application.fetch_env!(:auth_service, :firebase)
  defp emulator_host, do: config()[:auth_emulator_host]
  def emulator?, do: is_binary(emulator_host())

  @doc "demo- のプロジェクトは Emulator にしかないので、Emulator なしでは起動しない"
  def check_config! do
    if String.starts_with?(config()[:project_id], "demo-") and not emulator?() do
      raise "demo- のプロジェクトでは FIREBASE_AUTH_EMULATOR_HOST を指定してください"
    end

    :ok
  end

  defp identity_base,
    do: if(emulator?(), do: "http://#{emulator_host()}/identitytoolkit.googleapis.com/v1", else: "https://identitytoolkit.googleapis.com/v1")

  defp securetoken_base,
    do: if(emulator?(), do: "http://#{emulator_host()}/securetoken.googleapis.com/v1", else: "https://securetoken.googleapis.com/v1")

  defp client(base_url) do
    Req.new(base_url: base_url, params: [key: config()[:api_key]], retry: false, receive_timeout: 10_000)
    |> Req.merge(Application.get_env(:auth_service, :req_options, []))
  end

  defp call(base_url, path, options) do
    case Req.post(client(base_url), [url: path] ++ options) do
      {:ok, %Req.Response{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %Req.Response{body: %{"error" => %{"message" => message}}}} ->
        {:error, Error.from_firebase(message)}

      {:ok, %Req.Response{}} ->
        {:error, Error.upstream()}

      {:error, _exception} ->
        {:error, Error.unavailable()}
    end
  end

  defp to_session(body) do
    %{
      uid: body["localId"] || body["user_id"],
      id_token: body["idToken"] || body["id_token"],
      refresh_token: body["refreshToken"] || body["refresh_token"],
      expires_in: to_integer(body["expiresIn"] || body["expires_in"] || "3600")
    }
  end

  defp to_integer(value) when is_integer(value), do: value
  defp to_integer(value) when is_binary(value), do: String.to_integer(value)

  @doc "登録（メールアドレスとパスワード）"
  @spec sign_up(String.t(), String.t()) :: {:ok, session()} | {:error, Error.t()}
  def sign_up(email, password) do
    with {:ok, body} <-
           call(identity_base(), "/accounts:signUp", json: %{email: email, password: password, returnSecureToken: true}) do
      {:ok, to_session(body)}
    end
  end

  @doc "ログイン"
  @spec sign_in(String.t(), String.t()) :: {:ok, session()} | {:error, Error.t()}
  def sign_in(email, password) do
    with {:ok, body} <-
           call(identity_base(), "/accounts:signInWithPassword",
             json: %{email: email, password: password, returnSecureToken: true}
           ) do
      {:ok, to_session(body)}
    end
  end

  @doc "更新用のトークンで、ID トークンを取り直す"
  @spec refresh(String.t()) :: {:ok, session()} | {:error, Error.t()}
  def refresh(refresh_token) do
    with {:ok, body} <-
           call(securetoken_base(), "/token", form: [grant_type: "refresh_token", refresh_token: refresh_token]) do
      {:ok, to_session(body)}
    end
  end

  @doc "ID トークンから利用者を調べる（トークンが正しいかを Firebase が確かめる）"
  @spec lookup(String.t()) :: {:ok, user()} | {:error, Error.t()}
  def lookup(id_token) do
    case call(identity_base(), "/accounts:lookup", json: %{idToken: id_token}) do
      {:ok, %{"users" => [user | _]}} ->
        {:ok, %{uid: user["localId"], email: user["email"], email_verified: user["emailVerified"] == true}}

      {:ok, _} ->
        {:error, Error.unauthorized()}

      error ->
        error
    end
  end

  @doc "確認のメールを送る"
  def send_verify_email(id_token),
    do: ok(call(identity_base(), "/accounts:sendOobCode", json: %{requestType: "VERIFY_EMAIL", idToken: id_token}))

  @doc "パスワードの再設定のメールを送る"
  def send_password_reset(email),
    do: ok(call(identity_base(), "/accounts:sendOobCode", json: %{requestType: "PASSWORD_RESET", email: email}))

  @doc "パスワードを変える（新しいトークンが返る。ほかの端末のトークンは使えなくなる）"
  @spec change_password(String.t(), String.t()) :: {:ok, session()} | {:error, Error.t()}
  def change_password(id_token, new_password) do
    with {:ok, body} <-
           call(identity_base(), "/accounts:update",
             json: %{idToken: id_token, password: new_password, returnSecureToken: true}
           ) do
      {:ok, to_session(body)}
    end
  end

  @doc "退会（アカウントを消す）"
  def delete_account(id_token), do: ok(call(identity_base(), "/accounts:delete", json: %{idToken: id_token}))

  @doc "すべての端末からログアウトする（今までの更新用のトークンを使えなくする。管理者として呼ぶ）"
  def revoke_refresh_tokens(uid) do
    with {:ok, token} <- AuthService.AccessToken.fetch() do
      ok(
        call(identity_base(), "/projects/#{config()[:project_id]}/accounts:update",
          json: %{localId: uid, validSince: Integer.to_string(System.system_time(:second))},
          headers: [{"authorization", "Bearer #{token}"}]
        )
      )
    end
  end

  defp ok({:ok, _}), do: :ok
  defp ok(error), do: error
end
