defmodule AuthServiceWeb.FallbackController do
  @moduledoc "コントローラーが返したエラー（AuthService.Error）を JSON にする"
  use Phoenix.Controller, formats: [:json]

  def call(conn, {:error, %AuthService.Error{} = error}) do
    conn
    |> maybe_retry_after(error)
    |> put_status(error.status)
    |> json(%{error: %{code: error.code, message: error.message}})
  end

  defp maybe_retry_after(conn, %{retry_after: nil}), do: conn
  defp maybe_retry_after(conn, %{retry_after: seconds}), do: put_resp_header(conn, "retry-after", Integer.to_string(seconds))
end
