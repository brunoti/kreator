import gleam/string_builder.{type StringBuilder}
import kreator/dialect.{type Dialect}
import kreator/value.{type Value}
import kreator/utils/list.{head} as _
import gleam/list

pub type WhereType {
  And
  Or
}

pub type Where {
  WhereBasic(
    where_type: WhereType,
    column: String,
    operator: String,
    value: Value,
  )
  WhereWrapped(where_type: WhereType, list: List(Where))
}

pub fn new_where_list() -> List(Where) {
  []
}

pub fn flatten(
  where_list: List(Where),
) -> List(#(WhereType, String, String, Value)) {
  where_list
  |> list.flat_map(fn(where) {
    case where {
      WhereWrapped(_, where_list) -> flatten(where_list)
      WhereBasic(where_type, column, operator, value) -> [
        #(where_type, column, operator, value),
      ]
    }
  })
}

pub fn add(where_list: List(Where), new_where: Where) -> List(Where) {
  case where_list {
    [] -> [new_where]
    _ ->
      head(where_list)
      |> list.append({
        case list.last(where_list) {
          Ok(w) -> [w, new_where]
          Error(_) -> []
        }
      })
  }
}

// pub fn append(current where_list: List(Where), append append_list: List(Where), where_type where_type: WhereType) -> List(Where) {
//   case where_list {
//     [] -> append_list
//     [where] -> [Where(..where, where_type: where_type, next: append_list)]
//     _ ->
//       head(where_list)
//       |> list.append({
//         case list.last(where_list) {
//           Ok(where) -> [Where(..where, where_type: where_type, next: append_list)]
//           Error(_) -> []
//         }
//       })
//   }
// }

pub fn equals(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: "=",
    value: value,
    where_type: where_type,
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

pub fn type_to_string(value: WhereType, _dialect: Dialect) -> StringBuilder {
  case value {
    And -> string_builder.from_string("and")
    Or -> string_builder.from_string("or")
  }
}

pub fn values(where_list: List(Where)) -> List(Value) {
  where_list
  |> flatten()
  |> list.map(fn(item) {
    let #(_, _, _, value) = item
    value
  })
}
