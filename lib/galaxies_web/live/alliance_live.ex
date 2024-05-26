defmodule GalaxiesWeb.AllianceLive do
  use GalaxiesWeb, :live_view

  # alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    {:ok, GalaxiesWeb.Common.mount_live_context(socket)}
  end

  def render(assigns) do
    ~H"""
    Alliance
    """
  end
end
