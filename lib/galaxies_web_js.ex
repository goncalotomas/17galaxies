defmodule GalaxiesWebJS do
  alias Phoenix.LiveView.JS

  def hide_sidebar(js \\ %JS{}) do
    js
    |> JS.hide(to: "#off-canvas-menu-mobile", transition: {"transition-opacity ease-linear duration-300", "opacity-100", "opacity-0"})
    |> JS.hide(to: "#off-canvas-menu-backdrop", transition: {"transition-opacity ease-linear duration-300", "opacity-100", "opacity-0"})
    |> JS.hide(to: "#off-canvas-menu", transition: {"transition ease-in-out duration-300 transform", "translate-x-0", "-translate-x-full"})
    |> JS.hide(to: "#off-canvas-menu-close-button", transition: {"ease-in-out duration-300", "opacity-100", "opacity-0"})
  end

  def show_sidebar(js \\ %JS{}) do
    js
    |> JS.show(to: "#off-canvas-menu-mobile", transition: {"transition-opacity ease-linear duration-300", "opacity-0", "opacity-100"})
    |> JS.show(to: "#off-canvas-menu-backdrop", transition: {"transition-opacity ease-linear duration-300", "opacity-0", "opacity-100"})
    |> JS.show(to: "#off-canvas-menu", display: "flex", transition: {"transition ease-in-out duration-300 transform", "-translate-x-full", "translate-x-0"})
    |> JS.show(to: "#off-canvas-menu-close-button", transition: {"ease-in-out duration-300", "opacity-0", "opacity-100"})
  end
end
