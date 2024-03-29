defmodule Despite.Channels.UserSocketTest do
  use Despite.ChannelCase, async: true
  import Despite.TestHelpers
  alias Despite.{UserSocket, User}

  test "socket authentication with valid token" do
    user = insert_user
    {:ok, token, _full_claims} = Guardian.encode_and_sign(user, :token)
    assert {:ok, socket} = connect(UserSocket, %{"token" => token})
    assert socket.assigns.current_user.id == user.id
  end

  test "socket authentication with invalid token" do
    assert :error = connect(UserSocket, %{"token" => "1313"})
    assert :error = connect(UserSocket, %{})
  end
end
