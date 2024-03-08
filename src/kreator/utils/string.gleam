import gleam/string_builder.{type StringBuilder}

pub fn wrap_string_builder(
  string: StringBuilder,
  wrapper: String,
) -> string_builder.StringBuilder {
  string_builder.new()
  |> string_builder.append(wrapper)
  |> string_builder.append_builder(string)
  |> string_builder.append(wrapper)
}

pub fn parenthesify(string: StringBuilder) -> StringBuilder {
  case string_builder.is_empty(string) {
    True -> string_builder.new()
    False ->
      string_builder.new()
      |> string_builder.append("(")
      |> string_builder.append_builder(string)
      |> string_builder.append(")")
  }
}

pub fn wrap_string(
  string: String,
  wrapper: String,
) -> string_builder.StringBuilder {
  string_builder.new()
  |> string_builder.append(wrapper)
  |> string_builder.append(string)
  |> string_builder.append(wrapper)
}
