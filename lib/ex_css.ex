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

  at_token =
    ignore(string("@"))
    |> concat(identity_token)
    |> tag(:at_token)

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

  url_unquoted =
    repeat_until(choice([utf8_char([]), escape]), [ascii_char([?", ?', ?(, ?), ?\\, ?\s, ?\t, ?\n, ?\r, ?\f])])
    |> reduce({Kernel, :to_string, []})
    |> tag(:url_unquoted)

  url_token =
    ignore(string("url"))
    |> ignore(string("("))
    |> choice([string_token, url_unquoted])
    |> optional(ignore(whitespace_token))
    |> ignore(string(")"))
    |> tag(:url_token)

  e_number =
    ascii_string([?e, ?E], 1)
    |> optional(ascii_string([?+, ?-], 1))
    |> integer(min: 1)
    |> debug()

  decimal_number =
    optional(integer(min: 1))
    |> concat(string("."))
    |> concat(integer(min: 1))

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

  defparsec :css,
    repeat(choice([comment, url_token, whitespace_token, function_token, at_token, hash_token, string_token, percentage_token, dimension_token, number_token]))
end
