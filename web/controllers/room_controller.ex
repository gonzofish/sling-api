defmodule Sling.RoomController do
  use Sling.Web, :controller

  alias Sling.Room

  plug Guardian.Plug.EnsureAuthenticated, handler: Sling.SessionController

  def index(conn, _params) do
    rooms = Repo.all(Room)
    render(conn, "index.json", rooms: rooms)
  end

  def create(conn, room_params) do
    current_user = Guardian.Plug.current_resource(conn)
    changeset = Room.changeset(%Room{}, room_params)

    case Repo.insert(changeset) do
      {:ok, room} ->
        user_room_changeset = Sling.UserRoom.changeset(
          %Sling.UserRoom{},
          %{ room_id: room.id, user_id: current_user.id }
        )
        Repo.insert(user_room_changeset)

        conn
        |> put_status(:created)
        # |> put_resp_header("location", room_path(conn, :show, room))
        |> render("show.json", room: room)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Sling.ChangesetView, "error.json", changeset: changeset)
    end
  end

  def join(conn, %{ "id" => id }) do
    current_user = Guardian.Plug.current_resource(conn)
    room = Repo.get(Room, id)

    changeset = Sling.UserRoom.changeset(
      %Sling.UserRoom{},
      %{ room_id: room.id, user_id: current_user.id }
    )

    case Repo.insert(changeset) do
      { :ok, _user_room } ->
        conn
        |> put_status(:created)
        |> render("show.json", %{ room: room })
      { :error, changeset } ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(Sling.ChangesetView, "error.json", changeset: changeset)
    end
  end
end
