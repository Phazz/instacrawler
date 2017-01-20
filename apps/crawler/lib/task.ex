defmodule InstaCrawler.DistributedTask do
  use Supervisor

  alias InstaCrawler.Cluster

  def async(fun) do
    do_async(fun, :link)
  end

  def async_nolink(fun) do
    do_async(fun, :nolink)
  end

  defp do_async(fun, link_type) do
    owner = self()
    args = [owner, :monitor, get_info(owner), {:erlang, :apply, [fun, []]}]
    {:ok, pid} = Cluster.start(Supervisor, :start_child, [__MODULE__, args])
    if link_type == :link, do: Process.link(pid)
    ref = Process.monitor(pid)
    send pid, {owner, ref}
    %Task{pid: pid, ref: ref, owner: owner}
  end

  defdelegate await(task), to: Task, as: :await

  defp get_info(self) do
    {node(),
     case Process.info(self, :registered_name) do
       {:registered_name, []} -> self()
       {:registered_name, name} -> name
     end
    }
  end

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      worker(Task.Supervised, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

end
