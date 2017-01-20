defmodule InstaCrawler.PrivateAPI do
  alias InstaCrawler.PrivateAPI.{Crypto, Session, Request}

  @base_url "https://i.instagram.com/api/v1"

  def request(req, session)

  def request(%Request{resource: :login}, session) do
    url = @base_url <> "/accounts/login/"

    data = Poison.encode!(%{
      username: session.username,
      password: session.password,
      guid: session.identity.guid,
      device_id: session.identity.device_id,
      "Content-Type": "application/x-www-form-urlencoded; charset=UTF-8"
    })

    body = Crypto.sign_body(data)

    headers = [
      {"User-Agent", session.identity.user_agent},
      {"Content-Type", "application/x-www-form-urlencoded"}
    ]

    options = fetch_options(session)

    resp = HTTPoison.post!(url, body, headers, options)

    case resp do
      %{status_code: 200} ->
        cookies = resp.headers
        |> Enum.filter(fn {name, _} -> name == "Set-Cookie" end)
        |> Enum.map(&(parse_cookie/1))
        |> List.insert_at(-1, {"igfl", session.username})
        {:ok, %{session | cookies: cookies}}
      _ ->
        {:err, resp}
    end
  end
  def request(%Request{entity: entity, id: id, resource: resource, params: []}, session) do
    get_request(get_uri_for({entity, id, resource}), session)
  end
  def request(%Request{entity: entity, id: id, resource: resource, params: params}, session) do
    uri = get_uri_for({entity, id, resource})
    query = URI.encode_query(params)

    uri = if String.contains?(uri, "?") do
      uri <> "&" <> query
    else
      uri <> "?" <> query
    end

    get_request(uri, session)
  end

  defp get_uri_for({:username, username, :info}) do
    "/users/" <> username <> "/usernameinfo"
  end
  defp get_uri_for({:user, user_id, :geo_media}) do
    "/maps/user/#{user_id}"
  end
  defp get_uri_for({:user, user_id, :followers}) do
    "/friendships/#{user_id}/followers"
  end
  defp get_uri_for({:user, user_id, :following}) do
    "/friendships/#{user_id}/following"
  end
  defp get_uri_for({:user, user_id, :media_tags}) do
    "/usertags/#{user_id}/feed"
  end
  defp get_uri_for({:user, user_id, :media}) do
    "/feed/user/#{user_id}"
  end
  defp get_uri_for({:media, media_id, :info}) do
    "/media/#{media_id}/info"
  end
  defp get_uri_for({:media, media_id, :comments}) do
    "/media/#{media_id}/comments"
  end
  defp get_uri_for({:media, media_id, :likers}) do
    "/media/#{media_id}/likers"
  end
  defp get_uri_for({:hashtag, hashtag, :feed}) do
    "/feed/tag/#{hashtag}"
  end
  defp get_uri_for({:location, query, :search}) do
    "/location_search?" <> URI.encode_query([search_query: query])
  end
  defp get_uri_for({:location, location_id, :feed}) do
    "/feed/location/#{location_id}"
  end

  defp get_request(uri, session) do
    url = @base_url <> uri

    options = [
      hackney: [cookie: session.cookies, follow_redirect: true],
      ssl: [versions: [:"tlsv1.2"]] #workaround for broken ssl in 19.0
    ]

    options = Keyword.merge(options, fetch_options(session))

    headers = [
      {"User-Agent", session.identity.user_agent}
    ]

    resp = HTTPoison.get!(url, headers, options)

    case resp do
      %{status_code: 200} ->
        {:ok, Poison.Parser.parse!(resp.body, keys: :atoms)}
      _ ->
        {:err, resp}
    end
  end

  defp parse_cookie({_, content}) do
    List.first(:hackney_cookie.parse_cookie(content))
  end

  defp fetch_options(session) do
    case session.proxy_url do
      url when is_binary(url) ->
        case session.proxy_auth do
          {username, password} -> [proxy: url, proxy_auth: {username, password}]
          _ -> [proxy: url]
        end
      _ -> []
    end
  end

end
