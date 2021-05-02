defmodule ExCSS do
  @moduledoc """
  Documentation for ExCSS.Parser.
  """

  def parse(css) do
    with {:ok, tree, "", _, _, _} <- ExCSS.Parser.parse_css(css) do
      {:ok, tree}
    end
  end

  def stringify(tree, options \\ []) do
    tree
    |> ExCSS.Serializer.serialize(options)
    |> IO.iodata_to_binary()
  end
end
