defmodule ExCss do
  @moduledoc """
  Documentation for ExCss.Parser.
  """

  def parse(css) do
    with {:ok, tree, "", _, _, _} <- ExCss.Parser.parse_css(css) do
      {:ok, tree}
    end
  end

  def stringify(tree) do
    tree
    |> ExCss.Serializer.serialize()
    |> IO.iodata_to_binary()
  end
end
