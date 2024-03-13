import gleam/string_builder.{type StringBuilder}
import kreator/dialect.{type Dialect}
import kreator/value.{type Value, Null}
import kreator/utils/list.{head} as _
import gleam/list

pub type WhereType {
  And
  Or
}

pub type Operator {
  Eq
  Gt
  Lt
  GtEq
  LtEq
  NotEq
  Like
  NotLike
  IsNull
  IsNotNull
  In
  NotIn
}

pub type Where {
  WhereBasic(
    where_type: WhereType,
    column: String,
    operator: Operator,
    value: Value,
  )
  WhereWrapped(where_type: WhereType, list: List(Where))
}

pub fn new_where_list() -> List(Where) {
  []
}

pub fn flatten(
  where_list: List(Where),
) -> List(#(WhereType, String, Operator, Value)) {
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

pub fn equals(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(column: column, operator: Eq, value: value, where_type: where_type)
}

pub fn in(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(column: column, operator: In, value: value, where_type: where_type)
}

pub fn gt(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(column: column, operator: Gt, value: value, where_type: where_type)
}

pub fn lt(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(column: column, operator: Lt, value: value, where_type: where_type)
}

pub fn lte(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(column: column, operator: Lt, value: value, where_type: where_type)
}

pub fn not_in(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: NotIn,
    value: value,
    where_type: where_type,
  )
}

pub fn not_equals(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: NotEq,
    value: value,
    where_type: where_type,
  )
}

pub fn gte(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: GtEq,
    value: value,
    where_type: where_type,
  )
}

pub fn like(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: Like,
    value: value,
    where_type: where_type,
  )
}

pub fn not_like(
  column column: String,
  value value: Value,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: NotLike,
    value: value,
    where_type: where_type,
  )
}

pub fn null(column column: String, where_type where_type: WhereType) -> Where {
  WhereBasic(
    column: column,
    operator: IsNull,
    value: Null,
    where_type: where_type,
  )
}

pub fn not_null(
  column column: String,
  where_type where_type: WhereType,
) -> Where {
  WhereBasic(
    column: column,
    operator: IsNotNull,
    value: Null,
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

pub fn and_where_in(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, in(column, value, where_type: And))
}

pub fn and_where_like(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, like(column, value, where_type: And))
}

pub fn and_where_not_like(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, not_like(column, value, where_type: And))
}

pub fn and_where_not_in(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, not_in(column, value, where_type: And))
}

pub fn and_where_not_equals(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, not_equals(column, value, where_type: And))
}

pub fn and_where_gt(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, gt(column, value, where_type: And))
}

pub fn and_where_lt(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, lt(column, value, where_type: And))
}

pub fn and_where_gte(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, gte(column, value, where_type: And))
}

pub fn and_where_lte(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, lte(column, value, where_type: And))
}

pub fn and_where_null(where_list: List(Where), column: String) -> List(Where) {
  add(where_list, null(column, where_type: And))
}

pub fn and_where_not_null(
  where_list: List(Where),
  column: String,
) -> List(Where) {
  add(where_list, not_null(column, where_type: And))
}

pub fn or_where_equals(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, equals(column, value, where_type: Or))
}

pub fn or_where_in(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, in(column, value, where_type: Or))
}

pub fn or_where_like(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, like(column, value, where_type: Or))
}

pub fn or_where_not_like(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, not_like(column, value, where_type: Or))
}

pub fn or_where_not_in(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, not_in(column, value, where_type: Or))
}

pub fn or_where_not_equals(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, not_equals(column, value, where_type: Or))
}

pub fn or_where_gt(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, gt(column, value, where_type: Or))
}

pub fn or_where_lt(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, lt(column, value, where_type: Or))
}

pub fn or_where_gte(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, gte(column, value, where_type: Or))
}

pub fn or_where_lte(
  where_list: List(Where),
  column: String,
  value: Value,
) -> List(Where) {
  add(where_list, lte(column, value, where_type: Or))
}

pub fn operator_to_string(value: Operator, _dialect: Dialect) -> StringBuilder {
  case value {
    Eq -> string_builder.from_string("=")
    Gt -> string_builder.from_string(">")
    Lt -> string_builder.from_string("<")
    GtEq -> string_builder.from_string(">=")
    LtEq -> string_builder.from_string("<=")
    NotEq -> string_builder.from_string("<>")
    Like -> string_builder.from_string("like")
    NotLike -> string_builder.from_string("not like")
    IsNull -> string_builder.from_string("is null")
    IsNotNull -> string_builder.from_string("is not null")
    In -> string_builder.from_string("in")
    NotIn -> string_builder.from_string("not in")
  }
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
