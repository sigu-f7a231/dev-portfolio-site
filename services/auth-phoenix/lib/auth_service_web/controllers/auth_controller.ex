defmodule AuthServiceWeb.AuthController do
  use Phoenix.Controller, formats: [:json]

  alias AuthService.{Accounts, Error}

  action_fallback AuthServiceWeb.FallbackController

  def sign_up(conn, params) do
    with {:ok, session} <- Accounts.sign_up(params["email"], params["password"]) do
      conn |> put_status(201) |> json(session_json(session))
    end
  end

  def log_in(conn, params) do
    with {:ok, session} <- Accounts.log_in(params["email"], params["password"], client_ip(conn)) do
      json(conn, session_json(session))
    end
  end

  def refresh(conn, params) do
    with {:ok, session} <- Accounts.refresh(params["refreshToken"]) do
      json(conn, session_json(session))
    end
  end

  def me(conn, _params) do
    with {:ok, token} <- bearer(conn),
         {:ok, user} <- Accounts.me(token) do
      json(conn, %{uid: user.uid, email: user.email, emailVerified: user.email_verified})
    end
  end

  def log_out(conn, _params) do
    with {:ok, token} <- bearer(conn),
         :ok <- Accounts.log_out(token) do
      send_resp(conn, 204, "")
    end
  end

  def request_password_reset(conn, params) do
    with :ok <- Accounts.request_password_reset(params["email"]) do
      send_resp(conn, 204, "")
    end
  end

  def change_password(conn, params) do
    with {:ok, token} <- bearer(conn),
         {:ok, session} <- Accounts.change_password(token, params["newPassword"]) do
      json(conn, session_json(session))
    end
  end

  def delete_account(conn, _params) do
    with {:ok, token} <- bearer(conn),
         :ok <- Accounts.delete_account(token) do
      send_resp(conn, 204, "")
    end
  end

  # トークンは画面に返すだけで、ログには書かない。キャッシュさせない
  defp session_json(session) do
    %{uid: session.uid, idToken: session.id_token, refreshToken: session.refresh_token, expiresIn: session.expires_in}
  end

  defp bearer(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] when token != "" -> {:ok, String.trim(token)}
      _ -> {:error, Error.new(401, "unauthorized", "ログインしてください")}
    end
  end

  # nginx・Cloud Run を通ると、接続元は X-Forwarded-For の先頭
  defp client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [forwarded | _] -> forwarded |> String.split(",") |> hd() |> String.trim()
      [] -> conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end
end
