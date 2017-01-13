defmodule InstaCrawler.Router do
  use Plug.Router
  alias InstaCrawler.Crawler

  @json_type "application/json"

  plug :match
  plug :dispatch

  post "/crawl/user/:username" do
    uuid = UUID.uuid1()

    resp = %{
      id: uuid
    }

    conn
    |> send_json(200, resp)
  end

  match _ do
    conn |> send_json(404, %{error: "Not found"})
  end

  def send_json(conn, status, body) do
    conn
    |> put_resp_content_type(@json_type)
    |> send_resp(status, Poison.encode!(body))
  end

end
