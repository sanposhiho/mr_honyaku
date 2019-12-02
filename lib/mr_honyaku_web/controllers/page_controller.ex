defmodule MrHonyakuWeb.PageController do
  use MrHonyakuWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
