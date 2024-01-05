defmodule GalaxiesWeb.BuildingsLive do
  use Phoenix.LiveView

  @tick_interval 1000

  def mount(_params, _session, socket) do
    send_next_tick(self(), @tick_interval)
    {:ok, assign(socket, %{
      resource_count: 123,
      upgrade_cost: 1,
      mine_level: 0
    })}
  end

  def handle_event("inc_mine_level", _params, socket) do
    upgrade_cost = socket.assigns.upgrade_cost
    socket =
      if socket.assigns.resource_count >= upgrade_cost do
        socket
        |> update(:mine_level, &(&1 + 1))
        |> update(:upgrade_cost, fn _ -> upgrade_cost(socket.assigns.mine_level) end)
        |> update(:resource_count, &(&1 - upgrade_cost))
      else
        socket
      end
    {:noreply, socket}
  end

  def handle_info("update_resource_count", socket) do
    send_next_tick(self(), @tick_interval)
    {:noreply, update(socket, :resource_count, fn count ->
      count + trunc(:math.pow(2, socket.assigns.mine_level))
    end)}
  end

  defp send_next_tick(pid, interval) do
    :erlang.send_after(interval, pid, "update_resource_count")
  end

  defp upgrade_cost(level) do
    trunc(:math.pow(1.5, level))
  end
end
