defmodule Galaxies.Factory do
  use ExMachina.Ecto, repo: Galaxies.Repo

  def planet_factory do
    {galaxy, system, slot} =
      sequence(
        :coordinates,
        fn
          seq_number ->
            {div(seq_number, 15 * 500), div(rem(seq_number, 15 * 500), 15) + 1,
             rem(seq_number, 15) + 1}
        end,
        start_at: 7500
      )

    %Galaxies.Planet{
      name: "Earth",
      galaxy: galaxy,
      system: system,
      slot: slot,
      min_temperature: Enum.random(-40..40),
      max_temperature: Enum.random(-40..40),
      image_id: 1,
      player: build(:player),
      metal_units: 1000.0,
      crystal_units: 1000.0,
      deuterium_units: 1000.0
    }
  end

  def player_factory do
    %{
      username: sequence(:player, &"player-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      hashed_password: "password123"
    }
  end
end
