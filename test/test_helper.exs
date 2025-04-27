ExUnit.start()

defmodule TestHelper do
  def bare?(parents) do
    IO.inspect(parents, label: :bare?)
    parent = List.first(parents)
    parent in [:dimension_token, :function_token, :percentage_token]
  end

  def parse_json(file) do
    file
    |> File.read!()
    |> Jason.decode!()
    |> Enum.chunk_every(2)
  end

  def result_to_list({:ok, result, _rem, _context, _line, _offset}) do
    do_result_to_list(result, [])
  end

  def result_to_list({:error, message, _rem, _context, _line, _offset}) do
    [["error", message]]
  end

  defp do_result_to_list(list, parents) when is_list(list) do
    list
    |> Enum.flat_map(&do_result_to_list(&1, parents))
  end

  defp do_result_to_list({:stylesheet, values}, parents) do
    values
    |> Enum.reject(fn {key, _value} -> key in [:ws, :comment] end)
    |> Enum.flat_map(&do_result_to_list(&1, [:stylesheet | parents]))
  end

  defp do_result_to_list({:qualified_rule, values}, parents) do
    component_values =
      values
      |> Keyword.get(:component_values, [])
      |> Enum.flat_map(&do_result_to_list(&1, [:qualified_rule | parents]))

    curly_brackets_block =
      values
      |> Keyword.get(:curly_brackets_block, [])
      |> Enum.flat_map(&do_result_to_list(&1, [:qualified_rule | parents]))

    [["qualified rule", component_values, curly_brackets_block]]
  end

  defp do_result_to_list({:at_rule, values}, parents) do
    at_keyword_token =
      with [["ident", at_keyword_token]] <-
             values
             |> Keyword.get(:at_keyword_token, [])
             |> Enum.flat_map(&do_result_to_list(&1, [:at_rule | parents])) do
        at_keyword_token
      end

    component_values =
      values
      |> Keyword.get(:component_values, [])
      |> Enum.flat_map(&do_result_to_list(&1, parents))

    curly_brackets_block =
      values
      |> Keyword.get(:curly_brackets_block, [])
      |> IO.inspect(label: :curly_brackets_block)
      |> Enum.flat_map(&do_result_to_list(&1, parents))
    dbg(curly_brackets_block)

    [
      [
        "at-rule",
        at_keyword_token,
        component_values,
        if(curly_brackets_block == [], do: nil, else: curly_brackets_block)
      ]
    ]
  end

  defp do_result_to_list({:curly_bracket_open_token, _}, _parents) do
    []
  end

  defp do_result_to_list({:curly_bracket_close_token, _}, _parents) do
    []
  end

  defp do_result_to_list({:comment, _}, _parents) do
    []
  end

  defp do_result_to_list({:ws, _ws}, _parents) do
    [" "]
  end

  defp do_result_to_list({:colon_token, token}, _parents) do
    token
  end

  defp do_result_to_list({:cdo_token, token}, [parent | _rest])
       when parent in [:qualified_rule] do
    token
  end

  defp do_result_to_list({:cdo_token, _token}, _parents) do
    []
  end

  defp do_result_to_list({:cdc_token, token}, [parent | _rest])
       when parent in [:qualified_rule] do
    token
  end

  defp do_result_to_list({:cdc_token, _token}, _parents) do
    []
  end

  defp do_result_to_list({:semicolon_token, token}, _parent) do
    token
  end

  defp do_result_to_list({:delim_token, [delim]}, _parents) do
    [<<delim>>]
  end

  defp do_result_to_list({:error, message}, _parents) do
    [["error", message]]
  end

  defp do_result_to_list(binary, _parents) when is_binary(binary) do
    [binary]
  end

  defp do_result_to_list({:ident_token, values}, parents) do
    ident =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:ident_token | parents]))

    if bare?(parents) do
      ident
    else
      [["ident" | ident]]
    end
  end

  defp do_result_to_list({:component_value, value}, parents) do
    dbg(value)

    value
    |> Enum.flat_map(&do_result_to_list(&1, [:component_value | parents]))
  end

  defp do_result_to_list({:declaration_list, value}, parents) do
    value
    |> Enum.flat_map(&do_result_to_list(&1, [:declaration_list | parents]))
  end

  defp do_result_to_list({:declaration, value}, parents) do
    value
    |> Enum.flat_map(&do_result_to_list(&1, [:declaration | parents]))
  end

  defp to_int_or_float({integer, ""}, _), do: [integer, "integer"]

  defp to_int_or_float(_, number) do
    to_float(Float.parse("0" <> number))
  end

  def to_float({number, ""}), do: [number, "number"]
  def to_float(_), do: []

  defp int_or_float(number) do
    to_int_or_float(Integer.parse(number), number)
  end

  defp do_result_to_list({:number_token, [number]}, parents) do
    rest = int_or_float(number)

    if bare?(parents) do
      [number | rest]
    else
      [["number", number | rest]]
    end
  end

  defp do_result_to_list({:square_brackets_block, value}, parents) do
    new_value =
      value
      |> Enum.flat_map(&do_result_to_list(&1, [:square_brackets_block | parents]))

    [["[]" | new_value]]
  end

  defp do_result_to_list({:parenthesis_block, value}, parents) do
    new_value =
      value
      |> Enum.flat_map(&do_result_to_list(&1, [:parenthesis_block | parents]))
      |> List.flatten()

    [["()", new_value]]
  end

  defp do_result_to_list({:hash_token, [hash]}, _parents) do
    [["hash", hash, "id"]]
  end

  defp do_result_to_list({:at_keyword_token, values}, parents) do
    at_keyword_token =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:at_keyword_token | parents]))

    [at_keyword_token]
  end

  defp do_result_to_list({:dimension_token, values}, parents) do
    dimension_token =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:dimension_token | parents]))

    [["dimension" | dimension_token]]
  end

  #   ["function", "rgba",
  #     ["percentage", "100", 100, "integer"], ",", " ",
  #     ["percentage", "0", 0, "integer"], ",", " ",
  #     ["percentage", "50", 50, "integer"], ",", " ",
  #     ["number", ".5", 0.5, "number"]
  # ]
  # {:function_block, [{:function_token, [{:ident_token, ["rgba"]}, "("]}, {:component_value, [percentage_token: [{:number_token, ["100"]}, "%"]]}, {:component_value, [delim_token: ~c","]}, {:component_value, [ws: [" "]]}, {:component_value, [percentage_token: [{:number_token, ["0"]}, "%"]]}, {:component_value, [delim_token: ~c","]}, {:component_value, [ws: [" "]]}, {:component_value, [percentage_token: [{:number_token, ["50"]}, "%"]]}, {:component_value, [delim_token: ~c","]}, {:component_value, [ws: [" "]]}, {:component_value, [number_token: [".5"]]}, ")"]}

  defp do_result_to_list({:function_block, values}, parents) do
    IO.inspect(values, label: :values)

    function_block =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:function_block | parents]))

    IO.inspect(function_block, label: :function_block)

    [function_block]
  end

  defp do_result_to_list({:function_token, values}, parents) do
    IO.inspect(values, label: :values)

    function_token =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:function_token | parents]))

    IO.inspect(function_token, label: :function_token)

    ["function" | function_token]
  end

  # ["percentage", "100", 100, "integer"], ",", " ",
  # percentage_token: [{:number_token, ["100"]}, "%"]]

  defp do_result_to_list({:percentage_token, values}, parents) do
    percentage_token =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:percentage_token | parents]))

    IO.inspect(percentage_token, label: :percentage_token)

    [["percentage" | percentage_token]]
  end
end
