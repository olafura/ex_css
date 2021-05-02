defmodule ExCss.Serializer do
  @moduledoc """
  Documentation for ExCss.Serializer.
  """

  def serialize(tree, options \\ []) do
    map_options = options |> Enum.into(%{})

    do_walk_tree(tree, %{options: map_options})
  end

  defp do_walk_tree(list, context) when is_list(list) do
    Enum.map(list, &do_walk_tree(&1, context))
  end

  defp do_walk_tree({:stylesheet, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :style_sheet))
  end

  defp do_walk_tree({:qualified_rule, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :qualified_rule))
  end

  defp do_walk_tree({:component_values, body}, %{options: %{preserve_whitespace: true}} = context) do
    do_walk_tree(body, Map.put(context, :parent, :component_values))
  end

  defp do_walk_tree({:component_values, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :component_values))
    |> only_one_trailing_ws()
  end

  defp do_walk_tree({:component_value, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :component_value))
  end

  defp do_walk_tree({:curly_brackets_block, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :curly_brackets_block))
  end

  defp do_walk_tree({:curly_bracket_open_token, token}, _context) do
    token
  end

  defp do_walk_tree({:curly_bracket_close_token, token}, _context) do
    token
  end

  defp do_walk_tree({:declaration_list, body}, %{compact: true} = context) do
    do_walk_tree(body, Map.put(context, :parent, :declaration_list))
  end

  defp do_walk_tree({:declaration_list, body}, %{parent: :curly_brackets_block} = context) do
    do_walk_tree(body, Map.merge(context, %{parent: :declaration_list, indent_declaration: true}))
  end

  defp do_walk_tree({:declaration_list, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :declaration_list))
  end

  defp do_walk_tree({:declaration, body}, %{indent_declaration: true} = context) do
    ["  "] ++ do_walk_tree(body, Map.put(context, :parent, :declaration))
  end

  defp do_walk_tree({:declaration, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :declaration))
  end

  defp do_walk_tree({:ident_token, token}, _context) do
    token
  end

  defp do_walk_tree({:colon_token, token}, _context) do
    token
  end

  defp do_walk_tree({:semicolon_token, token}, _context) do
    token
  end

  defp do_walk_tree({:hash_token, token}, _context) do
    token
  end

  defp do_walk_tree({:ws, token}, %{options: %{preserve_whitespace: true}}) do
    token
  end

  defp do_walk_tree({:ws, token}, _) do
    List.first(token)
  end

  defp only_one_trailing_ws(io_data) do
    io_data
    |> IO.iodata_to_binary()
    |> String.trim()
    |> Kernel.<>(" ")
  end
end
