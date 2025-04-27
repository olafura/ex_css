defmodule ExCSS.Parser do
  @moduledoc """
  Documentation for ExCSS.Parser.
  """

  import NimbleParsec

  newline_single = ascii_string([?\n, ?\r, ?\f], 1)

  newline_double = string("\r\n")

  newline = choice([newline_double, newline_single]) |> replace("\n")

  # null_char = utf8_char([?0], 1)
  #
  # leading_surragate = utf8_char([0xD800..0xDBFF], 1)
  # trailing_surragate = utf8_char([0xDC00..0xDFFF], 1)

  # invalid_char = choice([null_char, leading_surragate, trailing_surragate]) |> replace("\uFFFD")

  whitespace = choice([string(" "), string("\t"), newline])

  comment =
    string("/*")
    |> repeat(
      lookahead_not(string("*/"))
      |> utf8_char([])
    )
    |> string("*/")
    |> ignore()

  empty_comment =
    ignore(string("/**/"))

  hex_digit = [0..9, ?a..?f, ?A..?F]

  escape =
    string("\\")
    |> ascii_string(hex_digit, min: 1, max: 6)
    |> tag(:escape)

  non_ascii = utf8_char(not: 0..127)

  ident_body =
    choice([ascii_char([?a..?z, ?A..?Z, ?_]), non_ascii])
    |> optional(repeat(choice([ascii_char([?a..?z, ?A..?Z, ?_, ?-]), non_ascii])))
    |> reduce({Kernel, :to_string, []})

  e_number =
    ascii_string([?e, ?E], 1)
    |> optional(ascii_string([?+, ?-], 1))
    |> integer(min: 1)

  decimal_number =
    optional(integer(min: 1))
    |> concat(string("."))
    |> concat(integer(min: 1))

  unicode_up_to_six_hex = ascii_string(hex_digit, min: 1, max: 6)

  # url_unquoted =
  #   repeat(
  #     lookahead_not(ascii_char([?", ?', ?(, ?), ?\\, ?\s, ?\t, ?\n, ?\r, ?\f]))
  #     |> choice([utf8_char([]), escape])
  #   )
  #   |> reduce({Kernel, :to_string, []})

  whitespace_token = times(whitespace, min: 1) |> tag(:ws)

  ident_token =
    choice([
      string("--"),
      optional(string("-"))
      |> choice([ident_body, escape])
    ])
    |> optional(choice([ident_body, escape]))
    |> tag(:ident_token)

  function_token =
    empty()
    |> concat(ident_token)
    |> ignore(string("("))
    |> tag(:function_token)

  at_keyword_token =
    ignore(string("@"))
    |> concat(ident_token)
    |> tag(:at_keyword_token)

  hash_token =
    ignore(string("#"))
    |> repeat(choice([ascii_char([?a..?z, ?A..?Z, ?_, ?-, ?0..?9]), escape]))
    |> reduce({Kernel, :to_string, []})
    |> tag(:hash_token)

  single_string_token =
    ignore(string("'"))
    |> repeat(
      lookahead_not(ascii_char([?']))
      |> choice([concat(string("\\"), newline), utf8_char(not: ?\\, not: ?\n), escape])
    )
    |> ignore(string("'"))
    |> reduce({Kernel, :to_string, []})

  double_string_token =
    ignore(string("\""))
    |> repeat(
      lookahead_not(ascii_char([?"]))
      |> choice([concat(string("\\"), newline), utf8_char(not: ?\\, not: ?\n), escape])
    )
    |> ignore(string("\""))
    |> reduce({Kernel, :to_string, []})

  string_token =
    choice([single_string_token, double_string_token])
    |> tag(:string_token)

  # Doesn't work yet
  # url_token =
  #   ignore(string("url"))
  #   |> ignore(string("("))
  #   |> choice([comment, empty_comment, string_token, url_unquoted])
  #   |> optional(ignore(whitespace_token))
  #   |> ignore(string(")"))
  #   |> tag(:url_token)

  number_token =
    optional(ascii_string([?+, ?-], 1))
    |> choice([decimal_number, integer(min: 1)])
    |> optional(e_number)
    |> reduce({Enum, :join, []})
    |> tag(:number_token)

  dimension_token =
    number_token
    |> concat(ident_token)
    |> tag(:dimension_token)

  percentage_token =
    number_token
    |> ignore(string("%"))
    |> tag(:percentage_token)

  unicode_range_token =
    ascii_string([?U, ?u], 1)
    |> concat(string("+"))
    |> choice([
      optional(ascii_string(hex_digit, min: 1, max: 5))
      |> ascii_string([??], min: 1, max: 6),
      unicode_up_to_six_hex,
      concat(
        concat(unicode_up_to_six_hex, string("-")),
        unicode_up_to_six_hex
      )
    ])
    |> reduce({Kernel, :to_string, []})
    |> tag(:unicode_range_token)

  include_match_token =
    string("~=")
    |> tag(:include_match_token)

  dash_match_token =
    string("|=")
    |> tag(:dash_match_token)

  prefix_match_token =
    string("^=")
    |> tag(:prefix_match_token)

  suffix_match_token =
    string("$=")
    |> tag(:suffix_match_token)

  substring_match_token =
    string("*=")
    |> tag(:substring_match_token)

  column_token =
    string("||")
    |> tag(:column_match_token)

  cdo_token =
    string("<!--")
    |> tag(:cdo_token)

  cdc_token =
    string("-->")
    |> tag(:cdc_token)

  semicolon_token =
    string(";")
    |> tag(:semicolon_token)

  colon_token =
    string(":")
    |> tag(:colon_token)

  curly_bracket_close_token =
    string("}")
    |> tag(:curly_bracket_close_token)

  curly_bracket_open_token =
    string("{")
    |> tag(:curly_bracket_open_token)

  delim_token =
    ascii_char([?#, ?+, ?-, ?., ?<, ?@, ?>, ?,])
    |> tag(:delim_token)

  preserved_token =
    choice([
      whitespace_token,
      cdo_token,
      cdc_token,
      ident_token,
      at_keyword_token,
      hash_token,
      single_string_token,
      double_string_token,
      string_token,
      # url_token,
      dimension_token,
      percentage_token,
      number_token,
      unicode_range_token,
      include_match_token,
      dash_match_token,
      prefix_match_token,
      suffix_match_token,
      substring_match_token,
      column_token,
      delim_token,
      colon_token
      # semicolon_token Have to figure how to exclude this in declaration list
    ])

  curly_brackets_block =
    curly_bracket_open_token
    |> optional(
      repeat(
        lookahead_not(curly_bracket_close_token)
        |> choice([parsec(:declaration_list), parsec(:component_value)])
      )
    )
    |> optional(curly_bracket_close_token)
    |> tag(:curly_brackets_block)

  parenthesis_block =
    ignore(string("("))
    |> optional(
      repeat(
        lookahead_not(string(")"))
        |> parsec(:component_value)
      )
    )
    |> optional(ignore(string(")")))
    |> tag(:parenthesis_block)

  square_brackets_block =
    ignore(string("["))
    |> optional(
      repeat(
        lookahead_not(string("]"))
        |> parsec(:component_value)
      )
    )
    |> optional(ignore(string("]")))
    |> tag(:square_brackets_block)

  function_block =
    function_token
    |> optional(
      repeat(
        lookahead_not(string(")"))
        |> parsec(:component_value)
      )
    )
    |> ignore(string(")"))
    |> tag(:function_block)

  at_rule =
    at_keyword_token
    |> optional(
      repeat(
        lookahead_not(
          choice([
            curly_brackets_block,
            semicolon_token
          ])
        )
        |> parsec(:component_value)
      )
    )
    |> post_traverse({:join_component_values, []})
    |> optional(
      choice([
        curly_brackets_block,
        semicolon_token
      ])
    )
    |> tag(:at_rule)

  qualified_rule =
    optional(
      repeat(
        lookahead_not(curly_brackets_block)
        |> parsec(:component_value)
      )
    )
    |> post_traverse({:join_component_values, []})
    |> concat(curly_brackets_block)
    |> tag(:qualified_rule)

  important =
    string("!")
    |> optional(whitespace_token)
    |> string("important")
    |> optional(whitespace_token)
    |> tag(:important)

  declaration =
    ident_token
    |> optional(whitespace_token)
    |> concat(colon_token)
    |> optional(
      repeat(parsec(:component_value))
      # |> post_traverse({:join_component_values, []}) return it in the wrong order
    )
    |> optional(important)
    |> tag(:declaration)

  semicolon_declaration_list =
    semicolon_token
    |> concat(parsec(:declaration_list))

  defparsec(
    :declaration_list,
    optional(whitespace_token)
    |> choice([
      comment,
      empty_comment,
      declaration,
      concat(declaration, semicolon_declaration_list),
      semicolon_declaration_list,
      concat(at_rule, parsec(:declaration_list))
    ])
    |> optional(semicolon_token)
    |> tag(:declaration_list)
  )

  defcombinatorp(
    :component_value,
    choice([
      function_block,
      preserved_token,
      curly_brackets_block,
      parenthesis_block,
      square_brackets_block
    ])
    #   |> debug()
    |> tag(:component_value)
  )

  stylesheet =
    optional(
      repeat(
        choice([
          comment,
          empty_comment,
          cdo_token,
          cdc_token,
          whitespace_token,
          at_rule,
          qualified_rule
        ])
      )
    )
    |> post_traverse({:check_for_error, []})
    |> tag(:stylesheet)

  defparsec(
    :parse_stylesheet,
    stylesheet
  )

  defparsec(
    :parse_component_value,
    pre_traverse(
      choice([
        times(
          choice([
            ignore(whitespace_token),
            ignore(newline),
            ignore(comment),
            ignore(empty_comment),
            parsec(:component_value)
          ]),
          min: 0,
          max: 10
        ),
        optional(ignore(whitespace_token)),
        optional(ignore(newline))
      ])
      |> post_traverse({:check_for_error_component_value, []}),
      {:check_for_empty_component_value, []}
    )
  )

  def parse_css(css) do
    css
    |> String.trim()
    |> parse_stylesheet()
  end

  defp check_for_error("", args, context, _line, _offset) do
    {"", args, context}
  end

  defp check_for_error(_, [], _context, _line, _offset) do
    {:error, "invalid"}
  end

  defp check_for_error(rest, args, context, _line, _offset) do
    {rest, [{:error, "invalid"} | args], context}
  end

  defp check_for_empty_component_value("", [], context, _line, _offset) do
    {:error, "empty"}
  end

  defp check_for_empty_component_value(rest, args, context, _line, _offset) do
    {rest, args, context}
  end

  defp check_for_error_component_value("", args, context, _line, _offset) do
    {"", args, context}
  end

  defp check_for_error_component_value(rest, [], _context, _line, _offset) do
    IO.inspect(rest, label: :rest)
    {:error, "empty"}
  end

  defp check_for_error_component_value(rest, args, context, _line, _offset) do
    IO.inspect(rest, label: :rest)
    IO.inspect(args, label: :args)
    IO.inspect(context, label: :context)

    if String.length(rest) == 1 do
      {rest, [{:error, rest} | args], context}
    else
      {rest, [{:error, "extra-input"}], context}
    end
  end

  defp join_component_values(rest, [], context, _line, _offset) do
    {rest, [], context}
  end

  defp join_component_values(rest, args, context, _line, _offset) do
    {at_keyword_token, at_rest} = Keyword.pop(:lists.reverse(args), :at_keyword_token)

    component_values =
      at_rest
      |> Enum.map(fn {:component_value, value} ->
        value
      end)

    if is_nil(at_keyword_token) do
      {rest, [{:component_values, component_values}], context}
    else
      {rest, [{:component_values, component_values}, {:at_keyword_token, at_keyword_token}],
       context}
    end
  end
end
