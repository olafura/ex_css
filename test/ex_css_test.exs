defmodule ExCssTest do
  use ExUnit.Case
  doctest ExCss

  test "simple css" do
    ExCss.Parser.parse_css("""
    p.something {
      color: red;
    }
    """)
  end

  test "spreadsheet" do
    TestHelper.parse_json("test/css-parsing-tests/stylesheet.json")
    |> Enum.map(fn [stylesheet, check] ->
      assert ExCss.Parser.parse_stylesheet(stylesheet) |> TestHelper.result_to_list() == check
    end)
  end
end
