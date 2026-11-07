defmodule AuthService.LoginThrottle do
  @moduledoc """
  ログインの総当たりの対策。同じメールアドレス・同じ接続元からの失敗を数え、
  `window_seconds` の間に `max_failures` 回失敗したら、その間は Firebase に問い合わせずに断る（429）。

  - 数えるのはこのサーバーのメモリ（ETS）の中だけ。台数を増やすと台ごとに数える（無料枠の構成では最大 1〜2 台）
  - メールアドレスはそのまま持たない（ハッシュにする）
  - Firebase 側にも同じような制限がある（`TOO_MANY_ATTEMPTS_TRY_LATER`）。こちらはそれより手前で止める
  """

  use GenServer

  @table __MODULE__

  def start_link(_opts), do: GenServer.start_link(__MODULE__, nil, name: __MODULE__)

  @impl true
  def init(nil) do
    :ets.new(@table, [:named_table, :public, :set, read_concurrency: true])
    {:ok, nil}
  end

  defp settings, do: Application.fetch_env!(:auth_service, :login_throttle)
  defp now, do: System.system_time(:second)

  @doc "メールアドレスと接続元から作るキー"
  def key(email, ip), do: :crypto.hash(:sha256, "#{email}|#{ip}")

  @doc "受け付けてよいか。だめなら `{:error, あと何秒}`"
  @spec check(binary()) :: :ok | {:error, pos_integer()}
  def check(key) do
    window = settings()[:window_seconds]

    case :ets.lookup(@table, key) do
      [{^key, count, first_at}] ->
        elapsed = now() - first_at

        cond do
          elapsed >= window ->
            :ets.delete(@table, key)
            :ok

          count >= settings()[:max_failures] ->
            {:error, max(window - elapsed, 1)}

          true ->
            :ok
        end

      [] ->
        :ok
    end
  end

  @doc "失敗を 1 回数える"
  def record_failure(key) do
    :ets.update_counter(@table, key, {2, 1}, {key, 0, now()})
    :ok
  end

  @doc "成功したら数え直す"
  def reset(key) do
    :ets.delete(@table, key)
    :ok
  end

  @doc "すべて消す（テスト用）"
  def clear do
    :ets.delete_all_objects(@table)
    :ok
  end
end
