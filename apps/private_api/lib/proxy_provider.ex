defmodule InstaCrawler.PrivateAPI.ProxyProvider do
  @proxy_list_file "proxylist.txt"

  def start_link do
    proxy_list_path =  Path.join([:code.priv_dir(:private_api), @proxy_list_file])
    proxy_list = File.stream!(proxy_list_path, [:read, :utf8])
      |> Stream.map(&String.trim(&1, "\n"))
      |> Stream.map(&String.split(&1, ":"))
      |> Stream.map(fn [host, port] -> {host, String.to_integer(port)} end)
      |> Enum.to_list
    Agent.start_link(fn -> proxy_list end, name: __MODULE__)
  end

  def random do
    Agent.get(__MODULE__, fn proxy_list -> Enum.random(proxy_list) end)
  end

end
