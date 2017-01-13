defmodule InstaCrawler.PrivateAPI.Session do
  defstruct identity: InstaCrawler.PrivateAPI.Identity.create_random,
    username: nil,
    password: nil,
    cookies: nil,
    proxy_url: :none,
    proxy_auth: nil

end
