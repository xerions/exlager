defmodule ExLager.JsonTest do
  use ExUnit.Case

  require Lager

  # NOTE
  # we are not able to capture lager output now
  # then this tests is only for checking by eyes

  test "Info with simple meta" do
    Lager.info("Message", [], [a: 1])
  end

  test "info with meta contains nested map" do
    Lager.info("Another message with nested data", [], [map: %{:c => 1}])
  end

  test "info with meta contains nested keyword" do
    Lager.info("Another message with nested data", [], [keyword: [c: 1]])
  end

  test "info with deep nested data" do
    meta = [a: 1,
            map: %{
              :keyword => [int: 2],
              :map => %{int: 2}
            }
    ]
    Lager.info("Another message with deep nested data", [], meta)
  end

  test "info with list of objects" do
    meta = [a: 1,
            b: [
              %{value: 1},
              %{value: 2}
            ],
            map: %{
              :keyword => [int: 2],
              :map => %{int: 2}
            }
    ]
    Lager.info("Another message with deep nested data", [], meta)
  end

  test "allow binaries in meta keys" do
    meta = [
      {"a", 1},
      {"b", 2}
    ]
    Lager.info("Another message with deep nested data", [], meta)
  end
  
  setup do
    Application.stop(:lager)
    Application.load(:lager)
    config = [level: :info,
              formatter: Lager.JsonFormatter,
              formatter_config: []
    ]
    Application.put_env(:lager, :handlers, [lager_console_backend: config])
    Application.start(:lager)
  end
end
