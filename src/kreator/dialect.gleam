import gleam/string_builder.{type StringBuilder}
import gleam/string
import kreator/utils/string.{wrap_string} as _

pub type Dialect {
  SQLite
  Postgres
  MySQL
}

pub fn symbol_quote(dialect: Dialect) -> String {
  case dialect {
    SQLite -> "`"
    Postgres -> "\""
    MySQL -> "`"
  }
}

pub fn string_quote(dialect: Dialect) -> String {
  case dialect {
    SQLite -> "'"
    Postgres -> "'"
    MySQL -> "'"
  }
}

pub fn wrap_column(column: String, dialect: Dialect) -> StringBuilder {
  let splitted_column = string.split(column, ".")
  case splitted_column {
    ["*"] -> string_builder.from_string("*")
    [table, _, column] ->
      [
        wrap_string(table, symbol_quote(dialect)),
        string_builder.from_string("."),
        wrap_string(column, symbol_quote(dialect)),
      ]
      |> string_builder.join("")
    [column] -> wrap_string(column, symbol_quote(dialect))
    _ -> wrap_string(column, symbol_quote(dialect))
  }
}
