defmodule GalaxiesWeb.ShipyardLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    socket = GalaxiesWeb.Common.mount_live_context(socket)
    planet_ships = Accounts.get_planet_ship_units(socket.assigns.current_planet)

    {:ok, assign(socket, :planet_ships, planet_ships)}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Shipyard — <%= @current_planet.name %>
        </h3>
      </div>
      <ul role="list" class="divide-y divide-gray-200">
        <li :for={ship <- @planet_ships}>
          <div class="px-4 py-4 sm:px-6">
            <div class="flex items-center justify-between">
              <div class="truncate text-sm font-medium text-indigo-600">
                <p>
                  <%= ship.name %>
                  <%= if ship.amount > 0 do %>
                    ( <%= ship.amount %> Available )
                  <% end %>
                </p>
              </div>
            </div>
            <div class="mt-2 flex justify-between">
              <div class="sm:flex">
                <div class="flex items-center text-sm text-gray-500">
                  <!-- we need the object-fit style to adapt any rectangular images into square ones -->
                  <img
                    class="h-32 w-32 mr-8 flex-none rounded bg-gray-50"
                    style="object-fit: cover;"
                    src={ship.image_src}
                  />
                  <%= ship.description_short %>
                </div>
              </div>
              <div class="ml-2 flex items-center text-sm text-gray-500">
                <%!-- <.simple_form for={@email_form} id="email_form" phx-submit="update_email">
                  <.input field={@email_form[:email]} type="number" label="Amount" required />
                  <.input
                    field={@email_form[:current_password]}
                    name="current_password"
                    id="current_password_for_email"
                    type="password"
                    label="Current password"
                    value={@email_form_current_password}
                    required
                  />
                  <:actions>
                    <.button phx-disable-with="Producing...">Produce</.button>
                  </:actions>
                </.simple_form> --%>
                Produce
              </div>
            </div>
          </div>
        </li>
      </ul>
    </div>
    """
  end
end
