defmodule Sling.UserRoomControllerTest do
  use Sling.ConnCase

  alias Sling.UserRoom
  @valid_attrs %{}
  @invalid_attrs %{}

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, user_room_path(conn, :index)
    assert json_response(conn, 200)["data"] == []
  end

  test "shows chosen resource", %{conn: conn} do
    user_room = Repo.insert! %UserRoom{}
    conn = get conn, user_room_path(conn, :show, user_room)
    assert json_response(conn, 200)["data"] == %{"id" => user_room.id,
      "user_id" => user_room.user_id,
      "room_id" => user_room.room_id}
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, user_room_path(conn, :show, -1)
    end
  end

  test "creates and renders resource when data is valid", %{conn: conn} do
    conn = post conn, user_room_path(conn, :create), user_room: @valid_attrs
    assert json_response(conn, 201)["data"]["id"]
    assert Repo.get_by(UserRoom, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, user_room_path(conn, :create), user_room: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "updates and renders chosen resource when data is valid", %{conn: conn} do
    user_room = Repo.insert! %UserRoom{}
    conn = put conn, user_room_path(conn, :update, user_room), user_room: @valid_attrs
    assert json_response(conn, 200)["data"]["id"]
    assert Repo.get_by(UserRoom, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    user_room = Repo.insert! %UserRoom{}
    conn = put conn, user_room_path(conn, :update, user_room), user_room: @invalid_attrs
    assert json_response(conn, 422)["errors"] != %{}
  end

  test "deletes chosen resource", %{conn: conn} do
    user_room = Repo.insert! %UserRoom{}
    conn = delete conn, user_room_path(conn, :delete, user_room)
    assert response(conn, 204)
    refute Repo.get(UserRoom, user_room.id)
  end
end
