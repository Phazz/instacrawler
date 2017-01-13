defmodule InstaCrawler.PrivateAPI do
  alias InstaCrawler.PrivateAPI.{Crypto, Session}

  @base_url "https://i.instagram.com/api/v1"

  def request(req, session)

  def request(:login, session) do
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

    resp = if session.proxy_url == :none do
      HTTPoison.post!(url, body, headers)
    else
      HTTPoison.post!(url, body, headers, proxy: session.proxy_url, proxy_auth: session.proxy_auth)
    end

    case resp do
      %{status_code: 200} ->
        cookies = resp.headers
        |> Enum.filter(fn {name, _} -> name == "Set-Cookie" end)
        |> Enum.map(&(parse_cookie/1))
        |> List.insert_at(-1, {"igfl", session.username})
        {:ok, cookies}
      _ ->
        {:err, resp}
    end
  end
  def request({entity, id, resource}, session) do
    get_request(get_uri_for({entity, id, resource}), session)
  end
  def request({entity, id, resource, opts}, session) when is_list(opts) do
    uri = "#{get_uri_for({entity, id, resource})}?"
    query_params = opts
    |> Enum.reduce("", fn {key, value}, acc -> acc <> "#{key}=value&" end)

    get_request(uri <> query_params, session)
  end

  def get_uri_for({:username, username, :info}) do
    "/users/#{username}/usernameinfo"
  end
  def get_uri_for({:user_id, user_id, :geo_media}) do
    "/maps/user/#{user_id}"
  end
  def get_uri_for({:user_id, user_id, :followers}) do
    "/friendships/#{user_id}/followers"
  end
  def get_uri_for({:user_id, user_id, :following}) do
    "/friendships/#{user_id}/following"
  end
  def get_uri_for({:user_id, user_id, :media_tags}) do
    "/usertags/#{user_id}/feed"
  end
  def get_uri_for({:user_id, user_id, :media}) do
    "/feed/user/#{user_id}"
  end
  def get_uri_for({:media, media_id, :info}) do
    "/media/#{media_id}/info"
  end
  def get_uri_for({:media, media_id, :comments}) do
    "/media/#{media_id}/comments"
  end
  def get_uri_for({:media, media_id, :likers}) do
    "/media/#{media_id}/likers"
  end
  def get_uri_for({:hashtag, hashtag, :feed}) do
    "/feed/tag/#{hashtag}"
  end

  defp get_request(uri, session) do
    url = @base_url <> uri

    options = [hackney: [cookie: session.cookies, follow_redirect: true]]

    options = case session.proxy_url  do
      :none -> options
      _ ->
        options
        |> Keyword.put(:proxy, session.proxy_url)
        |> Keyword.put(:proxy_auth, session.proxy_auth)
    end

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

end
