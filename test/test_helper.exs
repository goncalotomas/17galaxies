# load prerequisites
Galaxies.Prerequisites.load_static_prerequisites()
{:ok, _} = Application.ensure_all_started(:ex_machina)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Galaxies.Repo, :manual)
