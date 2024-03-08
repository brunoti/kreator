import gleam/string_builder.{type StringBuilder}
import kreator/dialect.{type Dialect}
import kreator/value.{type Value}
import kreator/utils/list.{head} as kl
import gleam/list

pub type WhereType {
  And
  Or
}

pub type Where {
  Where(
    column: String,
    operator: String,
    value: Value,
    where_type: WhereType,
    next: List(Where),
  )
}

pub fn new_where_list() -> List(Where) {
  []
}

pub fn add(where_list: List(Where), new_where: Where) -> List(Where) {
  case where_list {
    [] -> [new_where]
    _ ->
      head(where_list)
      |> list.append({
        case list.last(where_list) {
          Ok(where) -> [
            Where(..where, where_type: new_where.where_type),
            new_where,
          ]
          Error(_) -> []
        }
      })
  }
}

pub fn append(where_list: List(Where), append_list: List(Where)) -> List(Where) {
  case where_list {
    [] -> append_list
    [where] -> [Where(..where, where_type: Or, next: append_list)]
    _ ->
      head(where_list)
      |> list.append({
        case list.last(where_list) {
          Ok(where) -> [Where(..where, where_type: Or, next: append_list)]
          Error(_) -> []
        }
      })
  }
}

pub fn equals(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  Where(
    column: column,
    operator: "=",
    value: value,
    where_type: where_type,
    next: [],
  )
}

pub fn and_where_equals(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, equals(column, value, where_type: And))
}

pub fn or_where_equals(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, equals(column, value, where_type: Or))
}

pub fn type_to_string(
  value: WhereType,
  _dialect: Dialect,
) -> StringBuilder {
  case value {
    And -> string_builder.from_string("AND")
    Or -> string_builder.from_string("OR")
  }
}
