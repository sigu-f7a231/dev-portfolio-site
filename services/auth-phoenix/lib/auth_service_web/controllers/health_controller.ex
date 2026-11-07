defmodule AuthServiceWeb.HealthController do
  use Phoenix.Controller, formats: [:json]

  def show(conn, _params) do
    conn |> put_resp_header("cache-control", "no-store") |> json(%{status: "ok"})
  end
end
