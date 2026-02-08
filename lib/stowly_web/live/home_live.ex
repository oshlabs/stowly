defmodule StowlyWeb.HomeLive do
  use StowlyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, page_title: "Home")}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="hero min-h-[60vh]">
      <div class="hero-content text-center">
        <div class="max-w-md">
          <h1 class="text-5xl font-bold">Stowly</h1>
          <p class="py-6 text-base-content/70">
            Your home inventory management system. Organize collections, track items,
            and never lose track of your stuff again.
          </p>
          <.link navigate={~p"/collections"} class="btn btn-primary">
            Get Started
          </.link>
        </div>
      </div>
    </div>
    """
  end
end
