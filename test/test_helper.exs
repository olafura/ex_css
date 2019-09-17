ExUnit.start()

defmodule TestHelper do
  def parse_json(file) do
    file
    |> File.read!()
    |> Jason.decode!()
    |> Enum.chunk_every(2)
  end

  def result_to_list({:ok, result, _rem, _context, _line, _offset}, type) do
    do_result_to_list(result, [])
    |> clean_whitespace(type)
    |> check_for_empty(type)
  end

  def result_to_list({:error, message, _rem, _context, _line, _offset}, _) do
    [["error", message]]
  end

  def clean_whitespace(list, :component_value) do
    list
    |> Enum.reject(fn
      bin when is_binary(bin) -> 
        Regex.match?(~r/^\s$/, bin)
      _ ->
        false
    end)
  end

  def clean_whitespace(list, _type) do
    list
  end

  def check_for_empty([], :component_value) do
    [["error", "empty"]]
  end

  def check_for_empty(other, _type) do
    other
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
      |> Enum.flat_map(&do_result_to_list(&1, [:at_rule | parents]))

    curly_brackets_block =
      values
      |> Keyword.get(:curly_brackets_block, [])
      |> Enum.flat_map(&do_result_to_list(&1, parents))

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

  defp do_result_to_list({:token, token}, _parents) do
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

  defp do_result_to_list({:delim, [delim]}, _parents) do
    [<<delim>>]
  end

  # {:dimension_token, [number_token: ["4"], ident_token: [token: ["px"]]]}
  # ["dimension", "4", 4, "integer", "px"]
  defp do_result_to_list({:dimension_token, values}, parents) do
    number_token =
      values
      |> Keyword.take([:number_token])
      # |> IO.inspect()
      |> Enum.flat_map(&do_result_to_list(&1, [:dimension_token | parents]))
      |> hd()
      |> tl()
      # |> IO.inspect()

    ident_token =
      values
      |> Keyword.get(:ident_token, [])
      |> Enum.flat_map(&do_result_to_list(&1, [:dimension_token | parents]))
    [["dimension"] ++ number_token ++ ident_token]
  end

  # {:percentage_token, [{:number_token, ["100"]}, "%"]}
  # ["percentage", "100", 100, "integer"]
  defp do_result_to_list({:percentage_token, values}, parents) do
    number_token =
      values
      |> Enum.filter(&match?({_, _}, &1))
      |> Keyword.take([:number_token])
      |> Enum.flat_map(&do_result_to_list(&1, [:dimension_token | parents]))
      |> hd()
      |> tl()

    [["percentage" | number_token]]
  end

  # {:functional_block, [{:function_token, [{:ident_token, [token: ["rgba"]]}, "("]}, {:component_value, [percentage_token: [{:number_token, ["100"]}, "%"]]}, {:component_value, [delim: ',']}, {:component_value, [ws: [" "]]}, {:component_value, [percentage_token: [{:number_token, ["0"]}, "%"]]}, {:component_value, [delim: ',']}, {:component_value, [ws: [" "]]}, {:component_value, [percentage_token: [{:number_token, ["50"]}, "%"]]}, {:component_value, [delim: ',']}, {:component_value, [ws: [" "]]}, {:component_value, [number_token: [".5"]]}, ")"]}
  # [
    # "function",
    # "rgba",
    # ["percentage", "100", 100, "integer"],
    # ",",
    # " ",
    # ["percentage", "0", 0, "integer"],
    # ",",
    # " ",
    # ["percentage", "50", 50, "integer"],
    # ",",
    # " ",
    # ["number", ".5", 0.5, "number"]
  # ]

  defp do_result_to_list({:function_block, values}, parents) do
    # IO.inspect(values, label: :values)
    {function_token_value, rest} =
      values
      |> Enum.filter(&match?({_, _}, &1))
      |> Keyword.pop(:function_token, [])

    function_token =
      function_token_value
      |> Keyword.get(:ident_token, [])
      |> Enum.flat_map(&do_result_to_list(&1, [:function_block | parents]))
      |> List.first()
      # |> IO.inspect(label: :a)

    component_values =
      rest
      |> Enum.flat_map(&do_result_to_list(&1, [:function_block | parents]))
      # |> IO.inspect(label: :b)

    [["function", function_token | component_values]]
  end

  defp do_result_to_list({:error, message}, _parents) do
    IO.inspect(message, label: :error2)
    [["error", message]]
  end

  defp do_result_to_list(binary, _parents) when is_binary(binary) do
    [binary]
  end

  defp do_result_to_list({:ident_token, values}, parents) do
    ident =
      values
      |> Enum.flat_map(&do_result_to_list(&1, [:ident_token | parents]))

    [["ident" | ident]]
  end

  defp do_result_to_list({:component_value, value}, parents) do
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

  defp do_result_to_list({:number_token, [number]}, _parents) do
    rest =
      case Integer.parse(number) do
        {integer, ""} -> [integer, "integer"]
        _ ->
          if Regex.match?(~r/\.\d+/, number) do
            with {float, ""} <- Float.parse("0" <> number) do
              [float, "number"]
            end
          else
            with {float, ""} <- Float.parse(number) do
              [float, "number"]
            end
          end
      end

    [["number", number | rest]]
  end

  defp do_result_to_list({:square_brackets_block, value}, parents) do
    new_value =
      value
      |> Enum.flat_map(&do_result_to_list(&1, [:square_brackets_block | parents]))

    [["[]" | new_value]]
  end

  defp do_result_to_list({:curly_brackets_block, value}, parents) do
    new_value =
      value
      |> Enum.flat_map(&do_result_to_list(&1, [:curly_brackets_block | parents]))

    [["{}" | new_value]]
  end

  defp do_result_to_list({:parenthesis_block, value}, parents) do
    new_value =
      value
      |> Enum.flat_map(&do_result_to_list(&1, [:parenthesis_block | parents]))
      |> hd()

    [["()", new_value]]
  end

  defp do_result_to_list({:hash_token, [hash]}, _parents) do
    [["hash", hash, "id"]]
  end

  defp do_result_to_list({:at_keyword_token, values}, parents) do
    at_keyword_token =
      values
      |> Keyword.get(:ident_token, [])
      |> Enum.flat_map(&do_result_to_list(&1, [:at_keyword_token | parents]))
      |> hd()
      |> IO.inspect()

    [["at-keyword", at_keyword_token]]
  end
end
