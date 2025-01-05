defmodule GalaxiesWeb.FleetLive do
  use GalaxiesWeb, :live_view

  # alias Galaxies.Accounts
  @first_step 1
  @last_step 3

  def mount(_params, _session, socket) do
    {:ok, assign(socket, first_step: @first_step, last_step: @last_step)}
  end

  def handle_params(_unsigned_params, _uri, socket) do
    {:noreply, socket |> GalaxiesWeb.Common.mount_live_context() |> assign(:current_step, 1)}
  end

  def handle_event("previous_step", _params, socket) do
    {:noreply, assign(socket, :current_step, max(socket.assigns.current_step - 1, @first_step))}
  end

  def handle_event("next_step", _params, socket) do
    {:noreply, assign(socket, :current_step, min(socket.assigns.current_step + 1, @last_step))}
  end

  def render(assigns) do
    ~H"""
    Fleet
    <div class={unless @current_step == @first_step, do: "hidden"}>
      <p>Step 1</p>
    </div>
    <div class={unless @current_step == 2, do: "hidden"}>
      <p>Step 2</p>
    </div>
    <div class={unless @current_step == @last_step, do: "hidden"}>
      <p>Step 3</p>
    </div>
    <button :if={@current_step > @first_step} phx-click="previous_step">
      Back
    </button>
    <button :if={@current_step < @last_step} phx-click="next_step">
      Next
    </button>
    <button :if={@current_step == @last_step} phx-click="send">
      Send
    </button>
    """
  end
end
