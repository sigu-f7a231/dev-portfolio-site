defmodule AuthService.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    AuthService.Firebase.check_config!()

    children = [
      AuthService.LoginThrottle,
      AuthServiceWeb.Endpoint
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: AuthService.Supervisor)
  end

  @impl true
  def config_change(changed, _new, removed) do
    AuthServiceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
