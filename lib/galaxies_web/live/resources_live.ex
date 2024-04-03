defmodule GalaxiesWeb.ResourcesLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts
  alias Galaxies.Planets

  @timer_update_interval 1000

  def mount(_params, _session, socket) do
    current_planet = Accounts.get_active_planet(socket.assigns.current_player)
    _ = Planets.process_planet_events(current_planet.id)
    build_queue = Planets.get_building_queue(current_planet.id)
    planet_buildings = Accounts.get_planet_resource_buildings(current_planet)
    building_timers = timers_from_build_queue(build_queue)
    schedule_next_timer_update()

    {:ok,
     socket
     |> assign(:current_planet, current_planet)
     |> assign(:build_queue, build_queue)
     |> assign(:planet_buildings, planet_buildings)
     |> assign(:building_timers, building_timers)}
  end

  defp timers_from_build_queue([]), do: %{}

  defp timers_from_build_queue([building | _queue]) do
    %{
      building.building_id => DateTime.diff(building.completed_at, DateTime.utc_now(:second)) + 1
    }
  end

  def render(assigns) do
    ~H"""
    <div class="overflow-hidden bg-white sm:rounded-lg sm:shadow">
      <div class="border-b border-gray-200 bg-white px-4 py-5 sm:px-6">
        <h3 class="text-base font-semibold leading-6 text-gray-900">
          Resources — <%= @current_planet.name %>
        </h3>
      </div>
      <div
        :if={not Enum.empty?(@build_queue)}
        class="px-4 py-4 sm:px-6 border-b border-gray-200 bg-white"
      >
        <%!-- <div class="px-4 py-4 sm:px-6 border-b border-gray-200 bg-white"> --%>
        <div class="">
          <h4 class="text-base font-medium leading-4 text-gray-800">
            Active Build Queue
          </h4>
        </div>
        <div class="mt-2 flow-root">
          <div class="mx-4 my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full py-2 align-middle">
              <table class="min-w-full divide-y divide-gray-300">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-6 lg:pl-8"
                    >
                      Building
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Level
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">
                      Time to Complete
                    </th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-6 lg:pr-8">
                      <span class="sr-only">Cancel</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200">
                  <tr>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6 lg:pl-8">
                      <%= hd(@build_queue).building.name %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                      <%= hd(@build_queue).level %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                      <%= format_timer(@building_timers[hd(@build_queue).building_id]) %>
                    </td>
                    <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6 lg:pr-8">
                      <a href="#" class="text-indigo-600 hover:text-indigo-900">
                        Cancel<span class="sr-only">, <%= hd(@build_queue).building.name %></span>
                      </a>
                    </td>
                  </tr>
                  <tr :for={queued <- tl(@build_queue)}>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-900 sm:pl-6 lg:pl-8">
                      <%= queued.building.name %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                      <%= queued.level %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-500">
                      -
                    </td>
                    <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-6 lg:pr-8">
                      <a href="#" class="text-indigo-600 hover:text-indigo-900">
                        Cancel<span class="sr-only">, <%= queued.building.name %></span>
                      </a>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
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

  def handle_info(:update_timers, socket) do
    num_timers = Enum.count(socket.assigns.building_timers)

    building_timers =
      socket.assigns.building_timers
      |> Enum.reduce(%{}, fn
        {_building_id, secs}, acc when secs <= 1 ->
          acc

        {building_id, seconds}, acc ->
          Map.put(acc, building_id, seconds - 1)
      end)

    socket =
      if Enum.count(building_timers) != num_timers do
        # building timer reached zero, meaning some building was upgraded
        # re-fetch planet_buildings building queue and update building timers
        current_planet = socket.assigns.current_planet
        _ = Planets.process_planet_events(current_planet.id)
        build_queue = Planets.get_building_queue(current_planet.id)
        planet_buildings = Accounts.get_planet_resource_buildings(current_planet)

        building_timers = timers_from_build_queue(build_queue)

        socket
        |> assign(:build_queue, build_queue)
        |> assign(:building_timers, building_timers)
        |> assign(:planet_buildings, planet_buildings)
      else
        socket
        |> assign(:building_timers, building_timers)
      end

    # no need for periodic ticks if the current building timers Map is empty
    unless Enum.empty?(socket.assigns.building_timers) do
      schedule_next_timer_update()
    end

    {:noreply, socket}
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
        # TODO: doing the same as mount seems a bit too much, try to optimize
        current_planet = Accounts.get_active_planet(socket.assigns.current_player)
        _ = Planets.process_planet_events(current_planet.id)
        build_queue = Planets.get_building_queue(current_planet.id)
        planet_buildings = Accounts.get_planet_resource_buildings(current_planet)

        building_timers = timers_from_build_queue(build_queue)

        if Enum.empty?(socket.assigns.building_timers) do
          # building timers was previously empty so we need to restart the periodic timer update
          schedule_next_timer_update()
        end

        {:noreply,
         socket
         |> assign(:build_queue, build_queue)
         |> assign(:current_planet, current_planet)
         |> assign(:building_timers, building_timers)
         |> assign(:planet_buildings, planet_buildings)}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, error)}
    end
  end

  defp schedule_next_timer_update() do
    :erlang.send_after(@timer_update_interval, self(), :update_timers)
  end

  # defp list_replace(list, to_replace, acc \\ [])

  # defp list_replace([], _, acc), do: Enum.reverse(acc)

  # defp list_replace([h | t], to_replace, acc) do
  #   if h.id == to_replace.id do
  #     Enum.reverse(acc) ++ [to_replace | t]
  #   else
  #     list_replace(t, to_replace, [h | acc])
  #   end
  # end

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

  defp format_timer(nil), do: ""
  defp format_timer(seconds) when seconds >= 0 and seconds < 60, do: "#{seconds}s"

  defp format_timer(seconds) when seconds >= 0 and seconds < 3600,
    do: "#{div(seconds, 60)}m#{rem(seconds, 60)}s"

  defp format_timer(seconds) when seconds >= 0 and seconds < 86400,
    do: "#{div(seconds, 3600)}h#{div(rem(seconds, 3600), 60)}m#{rem(seconds, 60)}s"

  defp format_timer(seconds) when seconds >= 0,
    do:
      "#{div(seconds, 86400)}d#{div(rem(seconds, 86400), 3600)}h#{rem(seconds, 3600)}m#{rem(seconds, 60)}s"

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
