defmodule GalaxiesWeb.GalaxyLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:current_planet, Accounts.get_active_planet(socket.assigns.current_player))}
  end

  def render(assigns) do
    ~H"""
    Galaxy
    """
  end
end
