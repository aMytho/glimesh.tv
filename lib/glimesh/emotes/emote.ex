defmodule Glimesh.Emotes.Emote do
  @moduledoc false

  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  schema "emotes" do
    field :emote, :string
    belongs_to :channel, Glimesh.Streams.Channel
    field :animated, :boolean

    field :approved_at, :naive_datetime
    # belongs_to :approved_by, Glimesh.Accounts.User

    field :static_file, Glimesh.Uploaders.StaticEmote.Type
    field :animated_file, Glimesh.Uploaders.AnimatedEmote.Type

    timestamps()
  end

  @doc false
  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:emote, :animated, :approved_at])
    |> validate_required([:emote, :animated])
    |> validate_length(:emote, min: 2, max: 15)
    |> validate_conditional_file(attrs)
    |> unique_constraint(:emote)
  end

  def validate_conditional_file(changeset, attrs) do
    if get_field(changeset, :animated) do
      changeset
      |> cast_attachments(attrs, [:animated_file], allow_paths: true)
      |> validate_required(:animated_file)
    else
      changeset
      |> cast_attachments(attrs, [:static_file], allow_paths: true)
      |> validate_required(:static_file)
    end
  end
end