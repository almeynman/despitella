defmodule Despite.User do
  use Despite.Web, :model

  schema "users" do
    field :phone_number, :string
    field :gender, :string
    field :username, :string
    has_many :rooms, Despite.Room, foreign_key: :admin_id
    has_many :messages, Despite.Message, foreign_key: :sender_id

    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    # TODO gender should be validated as well
    |> cast(params, [:phone_number, :username, :gender])
    |> validate_required([:phone_number])
    |> validate_length(:username, min: 6, max: 100)
    |> unique_constraint(:phone_number)
  end
end
