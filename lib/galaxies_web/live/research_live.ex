defmodule GalaxiesWeb.ResearchLive do
  alias GalaxiesWeb.CommonComponents
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts

  import CommonComponents

  def mount(_params, _session, socket) do
    socket = GalaxiesWeb.Common.mount_live_context(socket)

    {:ok,
     assign(
       socket,
       :player_researches,
       Accounts.get_player_researches(socket.assigns.current_player)
     )}
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Research — {@current_planet.name}
        </h3>
      </div>
      <ul role="list" class="divide-y divide-gray-200">
        <li :for={research <- @player_researches}>
          <div class="px-4 py-4 sm:px-6">
            <div class="flex items-center justify-between">
              <div class="truncate text-sm font-medium text-indigo-600">
                {research.name}
                <%= if research.level > 0 do %>
                  ( Level {research.level} )
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
                    src={research.image_src}
                  />
                  <p>
                    {research.description_short}<br />
                    <.upgrade_cost formula={research.upgrade_cost_formula} level={research.level + 1} />
                  </p>
                </div>
              </div>
              <div class="ml-2 flex items-center text-sm text-indigo-500">
                <a href="#" class="block hover:bg-gray-50">
                  <.button phx-click={"upgrade_research:#{research.id}"}>
                    <%= if research.level == 0 do %>
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

  def handle_event("upgrade_research:" <> research_id, _value, socket) do
    building =
      Enum.find(socket.assigns.player_researches, fn building ->
        "#{building.id}" == research_id
      end)

    level = building.level + 1

    case Accounts.upgrade_player_research(
           socket.assigns.current_player,
           socket.assigns.current_planet,
           research_id,
           level
         ) do
      {:ok, _} ->
        updated_research = Map.put(building, :level, level)

        {metal, crystal, deuterium, _energy} =
          Galaxies.calc_upgrade_cost(building.upgrade_cost_formula, level)

        updated_planet =
          socket.assigns.current_planet
          |> Map.put(:metal_units, socket.assigns.current_planet.metal_units - metal)
          |> Map.put(:crystal_units, socket.assigns.current_planet.crystal_units - crystal)
          |> Map.put(:deuterium_units, socket.assigns.current_planet.deuterium_units - deuterium)

        player_researches = list_replace(socket.assigns.player_researches, updated_research)

        {:noreply,
         socket
         |> assign(:current_planet, updated_planet)
         |> assign(:player_researches, player_researches)}

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
end
