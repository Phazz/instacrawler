defmodule InstaCrawler.Extractor do

  def extract(map, keys) when is_map(map) do
    map
    |> Enum.flat_map(fn {key, value} ->
      if key in keys do
        [{key, value}]
      else
        extract(value, keys)
      end
    end)
  end

  def extract(list, keys) when is_list(list) do
    list
    |> Enum.flat_map(&extract(&1, keys))
  end

  def extract(_value, _keys) do
    []
  end

end
