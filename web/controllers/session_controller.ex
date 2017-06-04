defmodule Sling.SessionController do
  use Sling.Web, :controller

  def create(conn, params) do
    case do_authenticate(params) do
      { :ok, user } ->
        new_conn = Guardian.Plug.api_sign_in(conn, user, :access)
        jwt = Guardian.Plug.current_token(new_conn)

        new_conn
        |> put_status(:created)
        |> render("show.json", user: user, jwt: jwt)
      :error ->
        conn
        |> put_status(:unauthorized)
        |> render("error.json")
    end
  end

  def destroy(conn, _) do
    jwt = Guardian.Plug.current_token(conn)
    Guardian.revoke!(jwt)

    conn
    |> put_status(:ok)
    |> render("delete.json")
  end

  def refresh(conn, _params) do
    user = Guardian.Plug.current_resource(conn)
    jwt = Guardian.Plug.current_token(conn)
    { :ok, claims } = Guardian.Plug.claims(conn)

    case Guardian.refresh!(jwt, claims, %{ ttl: { 30, :days } }) do
      { :ok, new_jwt, _new_claims } ->
        conn
        |> put_status(:ok)
        |> render("show.json", user: user, jwt: new_jwt)
      { :error, reason } ->
        conn
        |> put_status(:unauthorized)
        |> render("forbidden.json", error: "Not authenticated")
    end

    def unauthorized(conn, _params) do
      conn
      |> put_status(:forbidden)
      |> render(Sling.SessionView, "forbidden.json", error: "Not Authenticated")
    end

    defp do_authenticate(%{ "email" => email, "password" => password }) do
      user = Repo.get_by(Sling.User, email: String.downcase(email))

      case do_check_password(user, password) do
        true -> { :ok, user }
        _ -> :error
      end
    end

    defp do_check_password(user, password) do
      case user do
        nil -> Comeonin.Bcrypt.dummy_checkpw()
        _ -> Comeonin.Bcrypt.checkpw(password, user.password_hash)
      end
    end
  end
end