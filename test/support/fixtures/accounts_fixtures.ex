defmodule Galaxies.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Galaxies.Accounts` context.
  """

  def unique_player_email, do: "player#{System.unique_integer()}@example.com"
  def valid_player_password, do: "hello world!"

  def valid_player_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_player_email(),
      password: valid_player_password()
    })
  end

  def player_fixture(attrs \\ %{}) do
    {:ok, player} =
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
