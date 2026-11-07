defmodule AuthService.MixProject do
  use Mix.Project

  # 認証サービス（Phoenix）。パスワードは Firebase Auth が持ち、ここは REST API を呼ぶ窓口になる
  # （docs/plan/decisions.md の D-01 の B）
  def project do
    [
      app: :auth_service,
      version: "0.1.0",
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [auth_service: [include_executables_for: [:unix]]]
    ]
  end

  def application do
    [mod: {AuthService.Application, []}, extra_applications: [:logger, :crypto]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:phoenix, "~> 1.7"},
      {:bandit, "~> 1.5"},
      {:jason, "~> 1.4"},
      # Firebase Auth の REST を呼ぶ。テストでは Req.Test で差し替える
      {:req, "~> 0.5"}
    ]
  end
end
