defmodule GalaxiesWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use GalaxiesWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # The default endpoint for testing
      @endpoint GalaxiesWeb.Endpoint

      use GalaxiesWeb, :verified_routes

      # Import conveniences for testing with connections
      import Plug.Conn
      import Phoenix.ConnTest
      import GalaxiesWeb.ConnCase
    end
  end

  setup tags do
    Galaxies.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  @doc """
  Setup helper that registers and logs in players.

      setup :register_and_log_in_player

  It stores an updated connection and a registered player in the
  test context.
  """
  def register_and_log_in_player(%{conn: conn}) do
    player = Galaxies.AccountsFixtures.player_fixture()
    %{conn: log_in_player(conn, player), player: player}
  end

  @doc """
  Logs the given `player` into the `conn`.

  It returns an updated `conn`.
  """
  def log_in_player(conn, player) do
    token = Galaxies.Accounts.generate_player_session_token(player)

    conn
    |> Phoenix.ConnTest.init_test_session(%{})
    |> Plug.Conn.put_session(:player_token, token)
  end
end
