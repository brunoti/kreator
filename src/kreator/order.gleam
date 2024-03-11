import gleam/string_builder.{type StringBuilder}
import kreator/dialect.{type Dialect}

pub type Order =
  #(String, Direction)

pub type Direction {
  Ascending
  Descending
}

pub fn type_to_string(direction: Direction) -> String {
  case direction {
    Ascending -> "asc"
    Descending -> "desc"
  }
}

pub fn to_string(order: Order, dialect: Dialect) -> StringBuilder {
  let #(column, direction) = order
  dialect.wrap_column(column, dialect)
  |> string_builder.append_builder(
    string_builder.from_strings([" ", type_to_string(direction)]),
  )
}
