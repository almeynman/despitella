defmodule Despite.UserController do
  use Despite.Web, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2]
  alias Despite.User
  alias Despite.Verification

  @expiration_duration 3600
  @randomizer Application.get_env(:despite, :randomizer)
  @twilio_api Application.get_env(:despite, :twilio_api)

  plug :scrub_params, "user" when action in [:create, :verify_phone_number]

  # def index(conn, _params) do
  #   users = Repo.all(User)
  #   render(conn, "index.json", users: users)
  # end

  def verify_phone_number(conn, %{"user" => %{"phone_number" => phone_number}}) do
    verification = Repo.get_by(Verification, %{phone_number: phone_number})
    code = @randomizer.generate_random_code
    save_and_send_code(conn, verification, phone_number, code)
  end

  defp save_and_send_code(conn, nil, phone_number, code) do
    changeset = Verification.changeset(%Verification{},
      %{phone_number: phone_number, code: code})
    IO.puts "#{inspect changeset}"
    case Repo.insert(changeset) do
      {:ok, verification} ->
        send_code(phone_number, code)
        conn
        |> put_status(:created)
        |> render(Despite.VerificationView, "show.json",
          verification: verification)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Despite.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp save_and_send_code(conn, verification, phone_number, code) do
    changeset = Verification.changeset(verification, %{code: code})

    case Repo.update(changeset) do
      {:ok, updated_verification} ->
        send_code(phone_number, code)
        conn
        |> render(Despite.VerificationView, "show.json",
          verification: updated_verification)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Despite.ChangesetView, "error.json", changeset: changeset)
    end
  end

  defp send_code(phone_number, code) do
    @twilio_api.Message.create(to: phone_number, from: "+12014312173", body: code)
  end

  def create(conn, %{"user" => user_params}) do
    verification = Repo.get_by(Verification,
      %{phone_number: user_params["phone_number"]})
    create(conn, verification, user_params)
  end

  def create(conn, nil, _) do
    conn
    |> put_status(:unauthorized)
    |> render(Despite.ErrorView, "error.json",
      %{reason: "This number has not requested verification code"})
  end

  def create(conn, verification, user_params) do
    expiration_datetime = verification |> to_expiration_datetime
    case checkpw(user_params["code"], verification.code_hash) do
      true ->
        comparison = Ecto.DateTime.compare(expiration_datetime, Ecto.DateTime.utc)
        create(conn, comparison, verification, user_params)
      _ ->
        # TODO here we can make verification not valid any more, otherwise
        # I can just keeo sending different codes until I find the right one
        conn
        |> put_status(:unauthorized)
        |> render(Despite.ErrorView, "error.json",
          %{reason: "Verification code is not correct, please retype or request another code"})
    end
  end

  def to_expiration_datetime(verification) do
    verification.updated_at
    |> Ecto.DateTime.to_erl
    |> :calendar.datetime_to_gregorian_seconds
    |> Kernel.+(@expiration_duration)
    |> :calendar.gregorian_seconds_to_datetime
    |> Ecto.DateTime.from_erl
  end

  def create(conn, :lt, _verification, _user_params) do
    conn
    |> put_status(:unauthorized)
    |> render(Despite.ErrorView, "error.json",
      %{reason: "The code for this number has already been expired, please request code one more time"})
  end

  def create(conn, _, _, user_params) do
    changeset = User.changeset(%User{}, user_params)

    case Repo.insert(changeset) do
      {:ok, user} ->
        conn
        |> put_status(:created)
        |> render("show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Despite.ChangesetView, "error.json", changeset: changeset)
    end
  end

  # def show(conn, %{"id" => id}) do
  #   user = Repo.get!(User, id)
  #   render(conn, "show.json", user: user)
  # end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Repo.get!(User, id)
    changeset = User.changeset(user, user_params)

    case Repo.update(changeset) do
      {:ok, user} ->
        render(conn, "show.json", user: user)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Despite.ChangesetView, "error.json", changeset: changeset)
    end
  end

  # def delete(conn, %{"id" => id}) do
  #   user = Repo.get!(User, id)
  #
  #   # Here we use delete! (with a bang) because we expect
  #   # it to always work (and if it does not, it will raise).
  #   Repo.delete!(user)
  #
  #   send_resp(conn, :no_content, "")
  # end
end
