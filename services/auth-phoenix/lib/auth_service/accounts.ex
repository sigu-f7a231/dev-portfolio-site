defmodule AuthService.Accounts do
  @moduledoc """
  認証の決まり（入力の確認・登録できる人・総当たりの対策）と、Firebase Auth の呼び出しをまとめる。
  画面からの入力はここで必ず確かめる（Firebase に送る前に）。
  """

  alias AuthService.{Error, Firebase, LoginThrottle}

  @min_password 8
  @max_password 128
  @max_email 254
  @email_format ~r/^[^\s@]+@[^\s@]+\.[^\s@]+$/

  @doc "登録して、確認のメールを送る（送れなくても登録は成功）"
  def sign_up(email, password) do
    with {:ok, email} <- normalize_email(email),
         :ok <- check_password(password),
         :ok <- check_allowlist(email),
         {:ok, session} <- Firebase.sign_up(email, password) do
      _ = Firebase.send_verify_email(session.id_token)
      {:ok, session}
    end
  end

  @doc "ログイン。続けて失敗したら、しばらく受け付けない"
  def log_in(email, password, ip) do
    with {:ok, email} <- normalize_email(email),
         :ok <- present(password, "パスワードを入れてください") do
      key = LoginThrottle.key(email, ip)

      case LoginThrottle.check(key) do
        {:error, retry_after} ->
          {:error, Error.new(429, "too_many_attempts", "続けて失敗したため、しばらくしてからお試しください", retry_after)}

        :ok ->
          case Firebase.sign_in(email, password) do
            {:ok, session} ->
              LoginThrottle.reset(key)
              {:ok, session}

            {:error, %Error{status: 401} = error} ->
              LoginThrottle.record_failure(key)
              {:error, error}

            error ->
              error
          end
      end
    end
  end

  @doc "更新用のトークンで、ID トークンを取り直す"
  def refresh(refresh_token) do
    with :ok <- present(refresh_token, "refreshToken を送ってください") do
      Firebase.refresh(refresh_token)
    end
  end

  @doc "自分の情報（ID トークンが正しいか）"
  def me(id_token), do: Firebase.lookup(id_token)

  @doc "すべての端末からログアウトする（更新用のトークンを使えなくする。ID トークンは期限（1 時間）まで残る）"
  def log_out(id_token) do
    with {:ok, user} <- Firebase.lookup(id_token) do
      Firebase.revoke_refresh_tokens(user.uid)
    end
  end

  @doc "パスワードの再設定のメールを送る。登録があるかどうかは返さない（いつも成功）"
  def request_password_reset(email) do
    with {:ok, email} <- normalize_email(email) do
      _ = Firebase.send_password_reset(email)
      :ok
    end
  end

  @doc "パスワードを変える（ログイン中）"
  def change_password(id_token, new_password) do
    with :ok <- check_password(new_password),
         {:ok, _user} <- Firebase.lookup(id_token) do
      Firebase.change_password(id_token, new_password)
    end
  end

  @doc "退会（アカウントを消す。データの削除は API（Hono）で行う。段階 5）"
  def delete_account(id_token) do
    with {:ok, _user} <- Firebase.lookup(id_token) do
      Firebase.delete_account(id_token)
    end
  end

  # ---------------- 入力の確認 ----------------

  @doc false
  def normalize_email(email) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    if byte_size(email) <= @max_email and Regex.match?(@email_format, email) do
      {:ok, email}
    else
      {:error, Error.new(400, "invalid_email", "メールアドレスの形が正しくありません")}
    end
  end

  def normalize_email(_), do: {:error, Error.new(400, "invalid_email", "メールアドレスを入れてください")}

  @doc false
  def check_password(password) when is_binary(password) do
    length = String.length(password)

    cond do
      length < @min_password -> {:error, Error.new(400, "weak_password", "パスワードは #{@min_password} 文字以上にしてください")}
      length > @max_password -> {:error, Error.new(400, "weak_password", "パスワードは #{@max_password} 文字までです")}
      true -> :ok
    end
  end

  def check_password(_), do: {:error, Error.new(400, "weak_password", "パスワードを入れてください")}

  defp check_allowlist(email) do
    case Application.get_env(:auth_service, :signup_allowlist, []) do
      [] -> :ok
      list -> if email in list, do: :ok, else: {:error, Error.new(403, "signup_not_allowed", "このメールアドレスでは登録できません")}
    end
  end

  defp present(value, _message) when is_binary(value) and value != "", do: :ok
  defp present(_, message), do: {:error, Error.bad_request(message)}
end
