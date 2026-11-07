defmodule AuthService.AccessToken do
  @moduledoc """
  管理者として Firebase Auth を呼ぶときのアクセストークン。
  - Emulator：`owner`（Emulator だけで使える管理者の印）
  - 本物：Cloud Run などのメタデータサーバーから、サービスアカウントのトークンを取る
  """

  alias AuthService.{Error, Firebase}

  @metadata_url "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token"

  @spec fetch() :: {:ok, String.t()} | {:error, Error.t()}
  def fetch do
    if Firebase.emulator?() do
      {:ok, "owner"}
    else
      options = [headers: [{"metadata-flavor", "Google"}], retry: false] ++ Application.get_env(:auth_service, :req_options, [])

      case Req.get(@metadata_url, options) do
        {:ok, %Req.Response{status: 200, body: %{"access_token" => token}}} -> {:ok, token}
        _ -> {:error, Error.unavailable()}
      end
    end
  end
end
