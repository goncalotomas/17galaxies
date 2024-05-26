defmodule GalaxiesWeb.GalaxyLive do
  use GalaxiesWeb, :live_view

  alias Galaxies.Accounts
  alias Galaxies.Planet
  alias Galaxies.Accounts.Player

  @galaxy_range 1..17
  @system_range 1..1499

  def mount(_params, _session, socket) do
    {:ok, GalaxiesWeb.Common.mount_live_context(socket)}
  end

  def handle_params(params, _uri, socket) do
    galaxy =
      valid_query_param_in_range(
        params["galaxy"],
        @galaxy_range,
        socket.assigns.current_planet.galaxy
      )

    system =
      valid_query_param_in_range(
        params["system"],
        @system_range,
        socket.assigns.current_planet.system
      )

    options = %{
      galaxy: galaxy,
      system: system
    }

    current_system = Accounts.get_galaxy_view(galaxy, system)

    slots =
      Enum.reduce(1..15, [], fn slot, acc ->
        planet = Enum.find(current_system, fn planet -> planet.slot == slot end)

        current_slot =
          if planet do
            {slot, planet, planet.player, possible_actions(socket.assigns.current_player, planet)}
          else
            {slot, nil, nil, [action(:colonize)]}
          end

        acc ++ [current_slot]
      end)

    {:noreply,
     assign(socket,
       slots: slots,
       options: options
     )}
  end

  def handle_event("go-to-system", %{"system" => system}, socket) do
    current_system = socket.assigns.options.system

    target_system = valid_query_param_in_range(system, @system_range, current_system)

    if current_system != target_system do
      {:noreply,
       push_patch(socket,
         to:
           ~p"/galaxy?#{query_param_keyword_list(%{socket.assigns.options | system: target_system})}"
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_event("go-to-galaxy", %{"galaxy" => galaxy}, socket) do
    current_galaxy = socket.assigns.options.galaxy

    target_galaxy = valid_query_param_in_range(galaxy, @galaxy_range, current_galaxy)

    if current_galaxy != target_galaxy do
      {:noreply,
       push_patch(socket,
         to:
           ~p"/galaxy?#{query_param_keyword_list(%{socket.assigns.options | galaxy: target_galaxy})}"
       )}
    else
      {:noreply, socket}
    end
  end

  # placeholder behaviour until spying is actually implemented.
  # will have to check (on context module) if:
  # - user has probes on this planet
  # - user is trying to spy a valid location
  # - user has permission to spy that location
  def handle_event("spy-" <> bin_coordinates, _params, socket) do
    [g, s, p] =
      String.split(bin_coordinates, "-")
      |> Enum.map(&Integer.parse/1)

    if g == :error or s == :error or p == :error do
      {:noreply, put_flash(socket, :error, "Invalid coordinates, stop messing around!")}
    else
      {galaxy, _} = g
      {system, _} = s
      {slot, _} = p

      {:noreply,
       put_flash(
         socket,
         :info,
         "10 Espionage probes dispatched to [#{galaxy}:#{system}:#{slot}]"
       )}
    end
  end

  def render(assigns) do
    ~H"""
    <div class="rounded-md bg-slate-950 py-4">
      <div class="px-4 sm:px-6 lg:px-8">
        <div class="">
          <div class="grid grid-cols-4 gap-4">
            <div class="col-start-2">
              <h4 class="text-center font-medium pb-1">Galaxy</h4>
              <nav
                class="isolate flex items-center justify-center -space-x-px rounded-md shadow-sm items-center"
                aria-label="Pagination"
              >
                <.link
                  :if={@options.galaxy > 1}
                  patch={
                    ~p"/galaxy?#{query_param_keyword_list(%{@options | galaxy: @options.galaxy - 1})}"
                  }
                  class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 bg-gray-50 hover:bg-indigo-50 focus:z-20 focus:outline-offset-0"
                >
                  <span class="sr-only">Previous</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </.link>
                <form
                  phx-change="go-to-galaxy"
                  phx-debounce="500"
                  class="relative inline-flex items-center px-4 py-2 text-sm bg-white font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0"
                >
                  <input
                    class="w-4 text-center"
                    name="galaxy"
                    placeholder={@options.galaxy}
                    value={@options.galaxy}
                  />
                </form>
                <.link
                  :if={@options.galaxy < 17}
                  patch={
                    ~p"/galaxy?#{query_param_keyword_list(%{@options | galaxy: @options.galaxy + 1})}"
                  }
                  class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 bg-gray-50 hover:bg-indigo-50 focus:z-20 focus:outline-offset-0"
                >
                  <span class="sr-only">Next</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </.link>
              </nav>
            </div>
            <div>
              <h4 class="text-center font-medium pb-1">Solar System</h4>
              <nav
                class="isolate flex items-center justify-center -space-x-px rounded-md shadow-sm items-center"
                aria-label="Pagination"
              >
                <.link
                  :if={@options.system > 1}
                  patch={
                    ~p"/galaxy?#{query_param_keyword_list(%{@options | system: @options.system - 1})}"
                  }
                  class="relative inline-flex items-center rounded-l-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 bg-gray-50 hover:bg-indigo-50 focus:z-20 focus:outline-offset-0"
                >
                  <span class="sr-only">Previous</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M12.79 5.23a.75.75 0 01-.02 1.06L8.832 10l3.938 3.71a.75.75 0 11-1.04 1.08l-4.5-4.25a.75.75 0 010-1.08l4.5-4.25a.75.75 0 011.06.02z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </.link>

                <form
                  class="relative inline-flex items-center px-4 py-2 text-sm bg-white font-semibold text-gray-700 ring-1 ring-inset ring-gray-300 focus:outline-offset-0"
                  phx-change="go-to-system"
                  phx-debounce="750"
                >
                  <input
                    class="w-12 text-center"
                    name="system"
                    placeholder={@options.system}
                    value={@options.system}
                  />
                </form>

                <.link
                  :if={@options.system < 1500}
                  patch={
                    ~p"/galaxy?#{query_param_keyword_list(%{@options | system: @options.system + 1})}"
                  }
                  class="relative inline-flex items-center rounded-r-md px-2 py-2 text-gray-400 ring-1 ring-inset ring-gray-300 bg-gray-50 hover:bg-indigo-50 focus:z-20 focus:outline-offset-0"
                >
                  <span class="sr-only">Next</span>
                  <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                    <path
                      fill-rule="evenodd"
                      d="M7.21 14.77a.75.75 0 01.02-1.06L11.168 10 7.23 6.29a.75.75 0 111.04-1.08l4.5 4.25a.75.75 0 010 1.08l-4.5 4.25a.75.75 0 01-1.06-.02z"
                      clip-rule="evenodd"
                    />
                  </svg>
                </.link>
              </nav>
            </div>
          </div>
        </div>
        <div class="mt-4 flow-root">
          <div class="-mx-4 -my-2 overflow-x-auto sm:-mx-6 lg:-mx-8">
            <div class="inline-block min-w-full pb-2 align-middle sm:px-6 lg:px-8">
              <table class="min-w-full divide-y divide-gray-700">
                <thead>
                  <tr>
                    <th
                      scope="col"
                      class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-white sm:pl-0"
                    >
                      Planet
                    </th>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                      Name
                    </th>
                    <%!-- <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                          Moon
                        </th> --%>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                      Player
                    </th>
                    <%!-- <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                          Alliance
                        </th> --%>
                    <th scope="col" class="px-3 py-3.5 text-left text-sm font-semibold text-white">
                      Actions
                    </th>
                    <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                      <span class="sr-only">Edit</span>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-800">
                  <tr :for={{slot, planet, player, actions} <- @slots}>
                    <td class="whitespace-nowrap py-1 pl-4 pr-3 text-sm font-medium text-white sm:pl-0">
                      <%= slot %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= if planet do %>
                        <%= planet.name %>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= if player do %>
                        <%= player.username %>
                      <% end %>
                    </td>
                    <td class="whitespace-nowrap px-3 py-1 text-sm text-gray-300">
                      <%= for action <- actions do %>
                        <%= if action.id == :spy do %>
                          <.link
                            phx-click={"spy-#{@options.galaxy}-#{@options.system}-#{slot}"}
                            class="text-indigo-400 hover:text-indigo-300 text-xs px-1"
                          >
                            <.icon name={action.icon_name} />
                            <%= action.name %>
                          </.link>
                        <% else %>
                          <.fleet_action_link params={
                            fleet_link_query_params(@options, slot, action.id)
                          }>
                            <.icon name={action.icon_name} />
                            <%= action.name %>
                          </.fleet_action_link>
                        <% end %>
                      <% end %>
                    </td>
                    <%!-- <td class="relative whitespace-nowrap py-1 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">

                        </td> --%>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end

  attr :params, :list, required: true
  slot :inner_block, required: true

  def fleet_action_link(assigns) do
    ~H"""
    <.link navigate={~p"/fleet?#{@params}"} class="text-indigo-400 hover:text-indigo-300 text-xs px-1">
      <%= render_slot(@inner_block) %>
    </.link>
    """
  end

  defp fleet_link_query_params(%{galaxy: galaxy, system: system}, slot, action)
       when action != :spy do
    [dest_galaxy: galaxy, dest_system: system, dest_slot: slot, action: action]
  end

  defp query_param_keyword_list(%{galaxy: galaxy, system: system}) do
    [galaxy: galaxy, system: system]
  end

  defp valid_query_param_in_range(param, range, default) when is_binary(param) do
    case Integer.parse(param) do
      {integer, _} ->
        if integer in range do
          integer
        else
          default
        end

      :error ->
        default
    end
  end

  defp valid_query_param_in_range(_param, _range, default), do: default

  defp possible_actions(%Player{id: id, current_planet_id: planet_id}, %Planet{
         id: planet_id,
         player: %Player{id: id}
       }) do
    # planet is the currently active planet.
    []
  end

  defp possible_actions(%Player{id: id}, %Planet{player: %Player{id: id}}) do
    # other planet from the same player
    [action(:transport)]
  end

  defp possible_actions(_player, _planet) do
    # other planet from another player
    [action(:spy), action(:attack), action(:transport)]
  end

  defp action(:transport) do
    %{
      id: :transport,
      icon_name: "hero-banknotes",
      name: "Transport"
    }
  end

  defp action(:attack) do
    %{
      id: :attack,
      icon_name: "hero-viewfinder-circle",
      name: "Attack"
    }
  end

  defp action(:spy) do
    %{
      id: :spy,
      icon_name: "hero-eye",
      name: "Spy"
    }
  end

  defp action(:colonize) do
    %{
      id: :colonize,
      icon_name: "hero-globe-alt",
      name: "Colonize"
    }
  end
end
