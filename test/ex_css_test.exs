defmodule ExCssTest do
  use ExUnit.Case
  doctest ExCss

  test "simple css" do
    ExCss.parse_css("""
    p.something {
      color: red;
    }
    """)
  end

  test "spreadsheet" do
    TestHelper.parse_json("test/css-parsing-tests/stylesheet.json")
    |> Enum.map(fn [stylesheet, check] ->
      assert ExCss.parse_stylesheet(stylesheet) |> TestHelper.result_to_list() == check
    end)
  end

  test "one_component_value" do
    TestHelper.parse_json("test/css-parsing-tests/one_component_value.json")
    |> Enum.map(fn [component_value, check] ->
      IO.inspect([component_value, check])
      assert ExCss.parse_component_value(component_value) |> TestHelper.result_to_list() == check
    end)
  end
end
