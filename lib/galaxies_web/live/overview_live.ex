defmodule GalaxiesWeb.OverviewLive do
  use Phoenix.LiveView

  def render(assigns) do
    ~H"""
    Welcome, <%= assigns.current_player.username %>
    """
  end
end
