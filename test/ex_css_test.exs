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

  test "spreadsheet" do
    TestHelper.parse_json("test/css-parsing-tests/stylesheet.json")
    |> Enum.map(fn [stylesheet, check] ->
      real = ExCSS.Parser.parse_stylesheet(stylesheet) |> TestHelper.result_to_list()
      assert real == check, "stylesheet: #{stylesheet}\nc: #{inspect(check)}\nr: #{inspect(real)}"
    end)
  end
end
