defmodule GalaxiesWeb.FacilitiesLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  def mount(_params, _session, socket) do
    current_planet = Accounts.get_active_planet(socket.assigns.current_player)
    planet_buildings = Accounts.get_planet_facilities_buildings(current_planet)

    {:ok,
     socket
     |> assign(:current_planet, current_planet)
     |> assign(:planet_buildings, planet_buildings)}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Facilities — <%= @current_planet.name %>
        </h3>
      </div>
      <ul role="list" class="divide-y divide-gray-200">
        <li :for={building <- @planet_buildings}>
          <div class="px-4 py-4 sm:px-6">
            <div class="flex items-center justify-between">
              <div class="truncate text-sm font-medium text-indigo-600">
                <%= building.name %>
                <%= if building.current_level > 0 do %>
                  ( Level <%= building.current_level %> )
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
                    <%= building.description_short %><br />
                    <%= list_upgrade_costs(building.upgrade_cost_formula, building.current_level + 1) %>
                  </p>
                </div>
              </div>
              <div class="ml-2 flex items-center text-sm text-indigo-500">
                <a href="#" class="block hover:bg-gray-50">
                  <.button phx-click={"upgrade:#{building.id}"}>
                    <%= if building.current_level == 0 do %>
                      Build
                    <% else %>
                      Upgrade
                    <% end %>
                  </.button>
                </a>
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

    case Accounts.upgrade_planet_building(socket.assigns.current_planet, building_id, level) do
      {:ok, _} ->
        updated_building = Map.put(building, :current_level, level)

        {metal, crystal, deuterium, energy} =
          Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, level)

        updated_planet =
          socket.assigns.current_planet
          |> Map.put(:metal_units, socket.assigns.current_planet.metal_units - metal)
          |> Map.put(:crystal_units, socket.assigns.current_planet.crystal_units - crystal)
          |> Map.put(:deuterium_units, socket.assigns.current_planet.deuterium_units - deuterium)
          |> Map.put(:available_energy, socket.assigns.current_planet.available_energy - energy)

        planet_buildings = list_replace(socket.assigns.planet_buildings, updated_building)

        {:noreply,
         socket
         |> assign(:current_planet, updated_planet)
         |> assign(:planet_buildings, planet_buildings)}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  defp list_replace(list, to_replace, acc \\ [])

  defp list_replace([], _, acc), do: Enum.reverse(acc)

  defp list_replace([h | t], to_replace, acc) do
    if h.id == to_replace.id do
      Enum.reverse(acc) ++ [to_replace | t]
    else
      list_replace(t, to_replace, [h | acc])
    end
  end

  defp list_upgrade_costs(nil, _current_level), do: nil

  defp list_upgrade_costs(formula, current_level) do
    {metal, crystal, deuterium, energy} = Galaxies.calc_upgrade_cost(formula, current_level)
    assigns = %{metal: metal, crystal: crystal, deuterium: deuterium, energy: energy}

    ~H"""
    Requirements:
    <%= if @metal > 0 do %>
      Metal: <strong><%= format_number(@metal) %></strong>
    <% end %>
    <%= if @crystal > 0 do %>
      Crystal: <strong><%= format_number(@crystal) %></strong>
    <% end %>
    <%= if @deuterium > 0 do %>
      Deuterium: <strong><%= format_number(@deuterium) %></strong>
    <% end %>
    <%= if @energy > 0 do %>
      Energy: <strong><%= format_number(@energy) %></strong>
    <% end %>
    """
  end

  defp format_number(number) when number < 1000, do: "#{number}"

  defp format_number(number) do
    number
    |> Kernel.to_string()
    |> String.reverse()
    |> String.split("", trim: true)
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end
end
