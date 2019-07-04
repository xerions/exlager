defmodule Lager.JsonFormatter do
  
  alias :lager_msg, as: LagerMsg

  @spec format(LagerMsg.lager_msg(), list()) :: any()
  def format(message, _config) do
    metadata = LagerMsg.metadata(message)
    keys = Keyword.keys(metadata)
    config = [:message, :timestamp, :severity | keys]
    map = List.foldl(config, %{}, fn(data, acc) ->
      value = get_data(data, message) |> to_str()
      key = case data do
        {_key, default} -> default
        key -> key
      end
      value = if is_binary(value) do
                for <<c <- value>>, into: <<>>, do: <<c::utf8>>
              else
                value
              end
      Map.put(acc, key, value)
    end) 
    "#{Poison.encode!(map)}" <> "\n"
  end

  @spec format(LagerMsg.lager_msg(), list(), list()) :: any()
  def format(message, config, _color), do: format(message, config)

  defp to_str(int) when is_integer(int), do: int
  defp to_str(map) when is_map(map), 
    do: for {k, v} <- map, into: %{}, do: {k, to_str(v)}
  defp to_str(tuple) when is_tuple(tuple),
    do: tuple |> Tuple.to_list() |> Enum.map(&to_str/1)
  defp to_str([{key, _}|_] = keyword) when is_atom(key), 
    do: Map.new(keyword) |> to_str()
  defp to_str([data | _rest] = list) when is_map(data) do
    Enum.map(list, fn (map) -> to_str(map) end)
  end
  defp to_str(value), do: to_string(value)

  defp get_data(:message, message), do: LagerMsg.message(message) 

  defp get_data(:timestamp, message), do:
    LagerMsg.timestamp(message) 
    |> format_timestap()

  defp get_data(:severity, message), do: LagerMsg.severity(message) 

  defp get_data(metadata, message) when is_atom(metadata) or is_list(metadata) or is_binary(metadata), do: 
    get_data({metadata, "undefined"}, message)

  defp get_data({metadata, absent}, message) do
    md = LagerMsg.metadata(message)
    case List.keyfind(md, metadata, 0) do
      nil -> absent
      {_, value} when is_pid(value) -> :erlang.pid_to_list(value)
      {_, value} -> value
    end
  end

  defp format_timestap(timestamp), do:
    timestamp
    |> :calendar.now_to_local_time()
    |> format_datetime()

  defp format_datetime({{y, m, d}, {h, mm, s}}), do:
    "#{y}-#{m}-#{d} #{h}:#{mm}:#{s}"

end
