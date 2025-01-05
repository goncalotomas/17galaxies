defmodule Galaxies.PlayerResearch do
  use Galaxies.Schema

  import Ecto.Changeset

  @primary_key false
  schema "player_researches" do
    field :current_level, :integer
    field :is_upgrading, :boolean
    field :upgrade_finished_at, :utc_datetime_usec

    belongs_to :player, Galaxies.Accounts.Player, primary_key: true
    belongs_to :research, Galaxies.Research, type: :integer, primary_key: true

    timestamps(type: :utc_datetime_usec)
  end

  def upgrade_changeset(player_research, attrs) do
    player_research
    |> cast(attrs, [:current_level, :is_upgrading, :upgrade_finished_at])
  end
end
