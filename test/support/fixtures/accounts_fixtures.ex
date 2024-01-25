defmodule Galaxies.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Galaxies.Accounts` context.
  """

  def unique_player_email, do: "player#{System.unique_integer()}@17galaxies.com"
  def unique_player_username, do: "player#{System.unique_integer([:positive])}"
  def valid_player_password, do: "hello world!"

  def valid_player_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      username: unique_player_username(),
      email: unique_player_email(),
      password: valid_player_password()
      # current_planet_id: "#{System.unique_integer()}"
    })
  end

  def player_fixture(attrs \\ %{}) do
    {:ok, %{player: player}} =
      attrs
      |> valid_player_attributes()
      |> Galaxies.Accounts.register_player()

    player
  end

  def extract_player_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
