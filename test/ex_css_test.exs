defmodule ExCSSTest do
  use ExUnit.Case
  doctest ExCSS

  test "simple css" do
    ExCSS.Parser.parse_css("""
    p.something {
      color: red;
    }
    """)
  end

  test "stylesheet" do
    TestHelper.parse_json("test/css-parsing-tests/stylesheet.json")
    |> Enum.map(fn [stylesheet, check] ->
      real = ExCSS.Parser.parse_stylesheet(stylesheet) |> TestHelper.result_to_list()

      assert real == check,
             "stylesheet: #{inspect(stylesheet)}\nc: #{inspect(check)}\nr: #{inspect(real)}"
    end)
  end

  test "one_component_value" do
    TestHelper.parse_json("test/css-parsing-tests/one_component_value.json")
    |> Enum.map(fn [component_value, check] ->
      real = ExCSS.Parser.parse_component_value(component_value) |> TestHelper.result_to_list()

      assert real == check,
             "component_value: #{inspect(component_value)}\nc: #{inspect(check)}\nr: #{inspect(real)}"
    end)
  end
end
