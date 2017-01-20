defmodule InstaCrawler.PrivateAPI.Session do
  defstruct identity: nil,
    username: nil,
    password: nil,
    cookies: nil,
    proxy_url: :nil,
    proxy_auth: nil
end
