defmodule Despite.RoomTest do
  use Despite.ModelCase

  alias Despite.Room

  @valid_attrs %{lat: "some content", long: "some content", radius: "some content", title: "some content"}
  @invalid_attrs %{}

  # test "changeset with valid attributes" do
  #   changeset = Room.changeset(%Room{}, @valid_attrs)
  #   assert changeset.valid?
  # end
  #
  # test "changeset with invalid attributes" do
  #   changeset = Room.changeset(%Room{}, @invalid_attrs)
  #   refute changeset.valid?
  # end
end
