defmodule AuthServiceWeb.ErrorJSON do
  @moduledoc "ルートがない・JSON が読めないなど、コントローラーの外で起きたエラー（同じ形の JSON）"

  def render("404.json", _assigns), do: %{error: %{code: "not_found", message: "ページがありません"}}
  def render("400.json", _assigns), do: %{error: %{code: "invalid_request", message: "JSON として読めません"}}
  def render("413.json", _assigns), do: %{error: %{code: "too_large", message: "送るデータが大きすぎます"}}
  def render("415.json", _assigns), do: %{error: %{code: "unsupported_media_type", message: "Content-Type は application/json にしてください"}}
  def render(_template, _assigns), do: %{error: %{code: "internal", message: "サーバーでエラーが起きました"}}
end
