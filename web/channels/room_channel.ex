defmodule Sling.RoomChannel do
  use Sling.Web, :channel

  def handle_in("new_message", params, socket) do
    changeset = socket.assigns.room
      |> build_assoc(:messages, user_id: socket.assigns.current_user.id)
      |> Sling.Message.changeset(params)

    case Repo.insert(changeset) do
      { :ok, message } ->
        do_broadcast_message(socket, message)
        { :reply, :ok, socket }
      { :error, changeset } ->
        { :reply, {
          :error,
          Phoenix.View.render(Sling.ChangesetView, "error.json", changeset: changeset)
        }, socket }
    end
  end

  defp do_broadcast_message(socket, message) do
    message = Repo.preload(message, :user)
    rendered_message = Phoenix.View.render_one(message, Sling.MessageView, "message.json")

    broadcast!(socket, "message_created", rendered_message)
  end

  def join("rooms:" <> room_id, _params, socket) do
    room = Repo.get!(Sling.Room, room_id)

    page = Sling.Message
      |> where([message], message.room_id == ^room.id)
      |> order_by([desc: :inserted_at, desc: :id])
      |> preload(:user)
      |> Sling.Repo.paginate()

    response = %{
      messages: Phoenix.View.render_many(page.entries, Sling.MessageView, "message.json"),
      pagination: Sling.PaginationHelpers.pagination(page),
      room: Phoenix.View.render_one(room, Sling.RoomView, "room.json")
    }

    { :ok, response, assign(socket, :room, room) }
  end

  def terminate(_reason, socket) do
    { :ok, socket }
  end
end