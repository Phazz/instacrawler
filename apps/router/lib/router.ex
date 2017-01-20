defmodule InstaCrawler.Router do
  use Plug.Router
  import Plug.Conn.Status
  alias InstaCrawler.{Router, PrivateAPI, Crawler}

  plug Plug.Parsers, parsers: [:json],
                   json_decoder: Poison

  plug :content_type, "application/json"
  plug :with_query_params
  plug :match
  plug :dispatch

  @not_found_message %Router.Payload{status: reason_phrase(404)}

  post "/:entity/:id/:resource" do
    request = parse_request(conn.body_params)

    api_request = %PrivateAPI.Request{
      entity: String.to_atom(entity),
      id: id,
      resource: String.to_atom(resource),
      params: conn.query_params
    }

    entrypoint = {%{}, api_request}

    scale = Map.get(request.options, :scale, 4)
    crawls = Map.get(request.options, :crawls, 16)

    keys = Map.get(request.options, :keys, "")

    parser_opts = if String.length(keys) > 0 do
      tokens = String.split(keys, ",")
      [keys: Enum.map(tokens, fn key -> String.to_atom(key) end)]
    else
      []
    end

    IO.inspect(parser_opts)

    {:ok, producer} = GenStage.from_enumerable([entrypoint])

    crawlers = 1..scale
    |> Enum.map(fn _ ->
      {:ok, crawler} = InstaCrawler.Crawler.Supervisor.new(request.session, crawls: crawls)
      GenStage.sync_subscribe(:storage, to: crawler, min_demand: 16, max_demand: 128)
      crawler
    end)

    parsers = 1..scale |> Enum.map(fn _ ->
      {:ok, parser} = InstaCrawler.Parser.Supervisor.new(parser_opts)
      parser
    end)

    for parser <- parsers do
      for crawler <- crawlers do
        GenStage.sync_subscribe(parser, to: crawler)
        GenStage.sync_subscribe(crawler, to: parser, max_demand: 64)
      end
    end

    for crawler <- crawlers do
      GenStage.sync_subscribe(crawler, to: producer)
    end

    conn
    |> send_json(202, api_request)
  end

  match _ do
    conn
    |> send_json(404, @not_found_message)
  end

  defp with_query_params(conn, opts) do
    conn
    |> fetch_query_params
  end

  defp content_type(conn, type) do
    conn
    |> put_resp_content_type(type)
  end

  defp send_json(conn, status, body) do
    conn
    |> send_resp(status, Poison.encode!(body))
  end

  defp parse_request(params) when is_map(params) do
    params = normalize(params)

    session = params[:session]
    |> Map.put(:identity, PrivateAPI.Identity.create_random)

    options = Map.get(params, :options, %{})

    if Map.has_key?(session, :proxy_url) do
      session = if Map.has_key?(session, :proxy_auth) do
        %{session | proxy_auth: normalize_auth(session.proxy_auth)}
      else
        session
      end
      %Router.Request{
        session: struct(PrivateAPI.Session, session),
        options: options
      }
    else
      %Router.Request{
        session: struct(PrivateAPI.Session, Map.put(session, :proxy_url, :none)),
        options: options
      }
    end
  end

  defp normalize(map) when is_map(map) do
    Enum.reduce(map, %{}, fn ({key, val}, acc) ->
      Map.put(acc, String.to_atom(key), normalize(val))
    end)
  end

  defp normalize(some) do
    some
  end

  defp normalize_auth(auth) do
    auth |> String.split(":") |> List.to_tuple
  end
end
