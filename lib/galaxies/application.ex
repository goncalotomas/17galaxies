defmodule Galaxies.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      GalaxiesWeb.Telemetry,
      Galaxies.Repo,
      {DNSCluster, query: Application.get_env(:galaxies, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Galaxies.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Galaxies.Finch},
      # Start a one-off task for loading static game entities
      {Task, &load_static_entities/0},
      # Start a worker by calling: Galaxies.Worker.start_link(arg)
      # {Galaxies.Worker, arg},
      # Start to serve requests, typically the last entry
      GalaxiesWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Galaxies.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    GalaxiesWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp load_static_entities() do
    tasks = [
      Task.async(fn -> Galaxies.Prerequisites.load_static_prerequisites() end),
      Task.async(fn -> Galaxies.Cached.Buildings.load_static_buildings() end)
    ]

    Task.await_many(tasks, :infinity)
    :ok
  end
end
