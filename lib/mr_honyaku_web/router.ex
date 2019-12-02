defmodule MrHonyakuWeb.Router do
  use MrHonyakuWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :put_secure_browser_headers
  end

  pipeline :csrf do
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", MrHonyakuWeb do
    pipe_through :browser

    post "/callback", BotController, :line_callback
    get  "/:message_id"  , BotController, :get_image
  end


  scope "/", MrHonyakuWeb do
    pipe_through [:browser, :csrf]

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", MrHonyakuWeb do
  #   pipe_through :api
  # end
end
