defmodule ExCss do
  @moduledoc """
  Documentation for ExCss.
  """

  import NimbleParsec

  comment =
    ignore(string("/*"))
    |> repeat_until(utf8_char([]), [string("*/")])
    |> ignore(string("*/"))
    |> reduce({Kernel, :to_string, []})
    |> tag(:comment)

  newline_single =
    ascii_string([?\n, ?\r, ?\f], 1)

  newline_double =
    string("\r\n")

  newline =
    choice([newline_double, newline_single])

  whitespace =
    choice([string(" "), string("\t"), newline])

  hex_digit = [0..9, ?a..?f, ?A..?F]

  escape =
    string("\\")
    |> ascii_string(hex_digit, min: 1, max: 6)

  token =
    ascii_char([?a..?z, ?A..?Z, ?_])
    |> optional(repeat(ascii_char([?a..?z, ?A..?Z, ?_, ?-])))
    |> reduce({Kernel, :to_string, []})
    |> tag(:token)

  e_number =
    ascii_string([?e, ?E], 1)
    |> optional(ascii_string([?+, ?-], 1))
    |> integer(min: 1)

  decimal_number =
    optional(integer(min: 1))
    |> concat(string("."))
    |> concat(integer(min: 1))

  unicode_up_to_six_hex =
    ascii_string(hex_digit, min: 1, max: 6)

  url_unquoted =
    repeat_until(choice([utf8_char([]), escape]), [ascii_char([?", ?', ?(, ?), ?\\, ?\s, ?\t, ?\n, ?\r, ?\f])])
    |> reduce({Kernel, :to_string, []})
    |> tag(:url_unquoted)

  whitespace_token =
    times(whitespace, min: 1)

  identity_token =
    optional(string("-"))
    |> choice([token, escape])
    |> optional(choice([token, escape]))
    |> tag(:identity_token)

  function_token =
    empty()
    |> concat(identity_token)
    |> concat(string("("))
    |> tag(:function_token)

  at_keyword_token =
    ignore(string("@"))
    |> concat(identity_token)
    |> tag(:at_keyword_token)

  hash_token =
    ignore(string("#"))
    |> repeat(choice([ascii_char([?a..?z, ?A..?Z, ?_, ?-, ?0..?9]), escape]))
    |> reduce({Kernel, :to_string, []})
    |> tag(:hash_token)

  single_string_token =
    ignore(string("'"))
    |> repeat_until(choice([concat(string("\\"), newline), utf8_char([not: ?\\, not: ?\n]), escape]), [ascii_char([?'])])
    |> ignore(string("'"))
    |> reduce({Kernel, :to_string, []})

  double_string_token =
    ignore(string("\""))
    |> repeat_until(choice([concat(string("\\"), newline), utf8_char([not: ?\\, not: ?\n]), escape]), [ascii_char([?"])])
    |> ignore(string("\""))
    |> reduce({Kernel, :to_string, []})

  string_token =
    choice([single_string_token, double_string_token])
    |> tag(:string_token)

  url_token =
    ignore(string("url"))
    |> ignore(string("("))
    |> choice([string_token, url_unquoted])
    |> optional(ignore(whitespace_token))
    |> ignore(string(")"))
    |> tag(:url_token)

  number_token =
    optional(ascii_string([?+, ?-], 1))
    |> choice([decimal_number, integer(min: 1)])
    |> optional(e_number)
    |> reduce({Enum, :join, []})
    |> tag(:number_token)

  dimension_token =
    number_token
    |> concat(identity_token)
    |> tag(:dimension_token)

  percentage_token =
    number_token
    |> concat(string("%"))
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

  dash_match_token =
    string("|=")

  prefix_match_token =
    string("^=")

  suffix_match_token =
    string("$=")

  substring_match_token =
    string("*=")

  column_token =
    string("||")

  cdo_token =
    string("<!--")

  cdc_token =
    string("-->")

  preserved_token =
    choice([
      parsec(:declaration_list),
      whitespace_token,
      identity_token,
      at_keyword_token,
      hash_token,
      single_string_token,
      double_string_token,
      string_token,
      url_token,
      number_token,
      dimension_token,
      percentage_token,
      unicode_range_token,
      include_match_token,
      dash_match_token,
      prefix_match_token,
      suffix_match_token,
      substring_match_token,
      column_token,
      cdo_token,
      cdc_token
    ])

  curly_brackets_block =
     string("{")
     |> optional(repeat(parsec(:component_value)))
     |> string("}")
     |> tag(:curly_brackets_block)

  parenthesis_block =
    string("(")
    |> optional(repeat(parsec(:component_value)))
    |> string(")")

  square_brackets_block =
    string("[")
    |> optional(repeat(parsec(:component_value)))
    |> string("]")

  functional_block =
    function_token
    |> optional(repeat(parsec(:component_value)))
    |> string(")")

  at_rule =
    at_keyword_token
    |> optional(repeat(parsec(:component_value)))
    |> choice([
      curly_brackets_block,
      string(";")
    ])
    |> tag(:at_rule)

  qualified_rule =
    optional(repeat(parsec(:component_value)))
    |> concat(curly_brackets_block)
    |> tag(:qualified_rule)

  important =
    string("!")
    |> optional(whitespace)
    |> string("important")
    |> optional(whitespace)

  declaration =
    identity_token
    |> optional(whitespace)
    |> concat(string(":"))
    |> debug()
    |> optional(repeat(parsec(:component_value)))
    |> optional(important)
    |> tag(:declaration)

  semicolon_declaration_list =
    string(";")
    |> concat(parsec(:declaration_list))

  defcombinatorp :declaration_list,
    optional(whitespace)
    |> choice([
      declaration,
      concat(declaration, semicolon_declaration_list),
      semicolon_declaration_list,
      concat(at_rule, parsec(:declaration_list))
    ])
    |> tag(:declaration_list)

  defcombinatorp :component_value,
    choice([
      preserved_token,
      # curly_brackets_block,
      parenthesis_block,
      square_brackets_block,
      functional_block
    ])
    |> tag(:component_value)
    |> debug()

  stylesheet =
    optional(
      repeat(
        choice([
          cdo_token,
          cdc_token,
          whitespace_token,
          qualified_rule,
          at_rule,
        ])
      )
    )
    |> tag(:stylesheet)

  defparsec :css,
    stylesheet
end
