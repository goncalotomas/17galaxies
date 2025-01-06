defmodule GalaxiesWeb.FacilitiesLive do
  alias GalaxiesWeb.CommonComponents
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts
  alias Galaxies.Planets

  import CommonComponents

  def mount(_params, _session, socket) do
    socket =
      socket
      |> GalaxiesWeb.Common.mount_live_context()
      |> load_build_queue()
      |> assign(page_title: "Facilities")

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Facilities — {@current_planet.name}
        </h3>
      </div>
      <div
        :if={not Enum.empty?(@build_queue)}
        class="px-4 py-4 sm:px-6 border-b border-gray-200 bg-white"
      >
        <.build_queue events={@build_queue} />
      </div>
      <ul role="list" class="divide-y divide-gray-200">
        <li :for={building <- @planet_buildings}>
          <div class="px-4 py-4 sm:px-6">
            <div class="flex items-center justify-between">
              <div class="truncate text-sm font-medium text-indigo-600">
                {building.name}
                <%= if building.current_level > 0 do %>
                  ( Level {building.current_level} )
                <% end %>
              </div>
            </div>
            <div class="mt-2 flex justify-between">
              <div class="sm:flex">
                <div class="flex items-center text-sm text-gray-500">
                  <!-- we need the object-fit style to adapt any rectangular images into square ones -->
                  <img
                    class="h-32 w-32 mr-8 flex-none rounded bg-gray-50"
                    style="object-fit: cover;"
                    src={building.image_src}
                  />
                  <p>
                    {building.description_short}<br />
                    <.upgrade_cost
                      formula={building.upgrade_cost_formula}
                      level={building.current_level + 1}
                    />
                  </p>
                </div>
              </div>
              <div class="ml-2 flex items-center text-sm text-indigo-500">
                <%!-- Should I move this logic out of the template? Probably. --%>
                <.link class="px-2 py-2" phx-click={"upgrade:#{building.id}"}>
                  <p class="my-auto">
                    <%= case Enum.empty?(@build_queue) do %>
                      <% false -> %>
                        Add to Queue
                      <% true when building.current_level == 0 -> %>
                        Build
                      <% true -> %>
                        Upgrade
                    <% end %>
                  </p>
                </.link>
              </div>
            </div>
          </div>
        </li>
      </ul>
    </div>
    """
  end

  def handle_event("upgrade:" <> building_id, _value, socket) do
    building =
      Enum.find(socket.assigns.planet_buildings, fn building ->
        "#{building.id}" == building_id
      end)

    level = building.current_level + 1

    case Accounts.upgrade_planet_building(
           socket.assigns.current_planet,
           String.to_integer(building_id),
           level
         ) do
      :ok ->
        {:noreply, load_build_queue(socket)}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  def handle_event("countdown-ended", _params, socket) do
    {:noreply, load_build_queue(socket)}
  end

  defp load_build_queue(socket) do
    _ = Planets.process_planet_events(socket.assigns.current_planet.id)
    build_queue = Planets.get_building_queue(socket.assigns.current_planet.id)
    planet_buildings = Accounts.get_planet_facilities_buildings(socket.assigns.current_planet)

    assign(socket, build_queue: build_queue, planet_buildings: planet_buildings)
  end
end
