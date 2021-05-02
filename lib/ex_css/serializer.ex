defmodule ExCSS.Serializer do
  @moduledoc """
  Documentation for ExCSS.Serializer.
  """

  def serialize(tree, options \\ []) do
    map_options = options |> Enum.into(%{})

    do_walk_tree(tree, %{options: map_options})
  end

  defp do_walk_tree(list, context) when is_list(list) do
    Enum.map(list, &do_walk_tree(&1, context))
  end

  defp do_walk_tree(binary, _context) when is_binary(binary) do
    binary
  end

  defp do_walk_tree({:stylesheet, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :stylesheet))
  end

  defp do_walk_tree({:qualified_rule, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :qualified_rule))
  end

  # defp do_walk_tree({:component_values, body}, %{options: %{preserve_whitespace: true}} = context) do
  #   do_walk_tree(body, Map.put(context, :parent, :component_values))
  # end

  defp do_walk_tree({:component_values, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :component_values))
    # |> only_one_trailing_ws()
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

  defp do_walk_tree({:at_rule, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :at_rule))
  end

  defp do_walk_tree({:dimension_token, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :dimension_token))
  end

  defp do_walk_tree({:percentage_token, body}, context) do
    do_walk_tree(body, Map.put(context, :parent, :percentage_token))
  end

  defp do_walk_tree({:parenthesis_block, body}, context) do
    ["("] ++ do_walk_tree(body, Map.put(context, :parent, :parenthesis_block)) ++ [")"]
  end

  defp do_walk_tree({:square_brackets_block, body}, context) do
    ["["] ++ do_walk_tree(body, Map.put(context, :parent, :square_brackets_block)) ++ ["]"]
  end

  defp do_walk_tree({:at_keyword_token, body}, context) do
    ["@"] ++ do_walk_tree(body, Map.put(context, :parent, :at_keyword_token))
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

  defp do_walk_tree({:escape, token}, _context) do
    token
  end

  defp do_walk_tree({:cdo_token, token}, _context) do
    token
  end

  defp do_walk_tree({:cdc_token, token}, _context) do
    token
  end

  defp do_walk_tree({:string_token, token}, _context) do
    token
  end

  defp do_walk_tree({:number_token, token}, _context) do
    token
  end

  defp do_walk_tree({:include_match_token, token}, _context) do
    token
  end

  defp do_walk_tree({:dash_match_token, token}, _context) do
    token
  end

  defp do_walk_tree({:prefix_match_token, token}, _context) do
    token
  end

  defp do_walk_tree({:suffix_match_token, token}, _context) do
    token
  end

  defp do_walk_tree({:substring_match_token, token}, _context) do
    token
  end

  defp do_walk_tree({:column_match_token, token}, _context) do
    token
  end

  defp do_walk_tree({:delim_token, token}, _context) do
    <<token>>
  end

  defp do_walk_tree({:important, token}, _context) do
    token
  end

  defp do_walk_tree({:ws, token}, %{options: %{preserve_whitespace: true}}) do
    token
  end

  defp do_walk_tree({:ws, _token}, %{parent: :stylesheet, options: %{compact: true}}) do
    []
  end

  defp do_walk_tree({:ws, token}, _context) do
    List.first(token)
  end

  defp do_walk_tree({:comment, _token}, %{options: %{compact: true}}) do
    []
  end

  defp do_walk_tree({:comment, token}, _context) do
    ["/*"] ++ token ++ ["*/"]
  end

  """
  Missing implementations
  :function_token
  :unicode_range_token
  :function_block
  """

  # defp only_one_trailing_ws(io_data) do
  #   io_data
  #   |> IO.iodata_to_binary()
  #   |> String.trim()
  #   |> Kernel.<>(" ")
  # end
end
