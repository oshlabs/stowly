defmodule StowlyWeb.Router do
  use StowlyWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", StowlyWeb do
    pipe_through :api
  end
end
