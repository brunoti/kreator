import gleam/list
import gleam/dict
import gleam/string_builder.{type StringBuilder}
import kreator/order.{type Direction, type Order}
import kreator/where.{type Where, WhereBasic, WhereWrapped} as w
import kreator/value.{type Value} as v
import kreator/dialect.{type Dialect}
import kreator/query.{type Query, Query}
import kreator/utils/string.{parenthesify, wrap_string, wrap_string_builder} as _

pub type Method {
  Select
  Insert
  Update
  Delete
}

pub type Blueprint {
  Blueprint(
    method: Method,
    table: String,
    columns: List(String),
    order_by: List(Order),
    where_clauses: List(Where),
    data: List(#(String, Value)),
  )
}

pub fn table(table: String) -> Blueprint {
  Blueprint(
    table: table,
    columns: ["*"],
    order_by: [],
    where_clauses: [],
    data: [],
    method: Select,
  )
}

pub fn select(blueprint: Blueprint, select: List(String)) -> Blueprint {
  Blueprint(..blueprint, columns: select, method: Select)
}

pub fn insert(blueprint: Blueprint, data: List(#(String, Value))) -> Blueprint {
  Blueprint(..blueprint, data: data, method: Insert)
}

pub fn update(blueprint: Blueprint, data: List(#(String, Value))) -> Blueprint {
  Blueprint(..blueprint, data: data, method: Update)
}

pub fn delete(blueprint: Blueprint) -> Blueprint {
  Blueprint(..blueprint, method: Delete)
}

pub fn order_by(
  blueprint: Blueprint,
  column column: String,
  direction direction: Direction,
) -> Blueprint {
  Blueprint(
    ..blueprint,
    order_by: list.append(blueprint.order_by, [#(column, direction)]),
  )
}

pub fn where(
  blueprint: Blueprint,
  fun: fn(List(Where)) -> List(Where),
) -> Blueprint {
  Blueprint(..blueprint, where_clauses: fun(blueprint.where_clauses))
}

pub fn and_where(
  blueprint: Blueprint,
  fun: fn(List(Where)) -> List(Where),
) -> Blueprint {
  Blueprint(
    ..blueprint,
    where_clauses: w.add(
      blueprint.where_clauses,
      WhereWrapped(w.And, fun(w.new_where_list())),
    ),
  )
}

pub fn or_where(
  blueprint: Blueprint,
  fun: fn(List(Where)) -> List(Where),
) -> Blueprint {
  Blueprint(
    ..blueprint,
    where_clauses: w.add(
      blueprint.where_clauses,
      WhereWrapped(w.Or, fun(w.new_where_list())),
    ),
  )
}

fn where_builder_do(
  where_clauses: List(Where),
  dialect: Dialect,
) -> StringBuilder {
  string_builder.new()
  |> string_builder.append_builder(string_builder.join(
    where_clauses
      |> list.index_map(fn(where_clause, i) {
        let is_first = i == 0
        let connector = case is_first {
          False ->
            w.type_to_string(where_clause.where_type, dialect)
            |> wrap_string_builder(" ")
          True -> string_builder.new()
        }

        case where_clause {
          WhereWrapped(_, next) -> {
            case list.is_empty(next) {
              True -> string_builder.new()
              False ->
                connector
                |> string_builder.append_builder(
                  where_builder_do(next, dialect)
                  |> parenthesify,
                )
            }
          }
          WhereBasic(_, column, operator, value) -> {
            connector
            |> string_builder.append_builder(dialect.wrap_column(
              column,
              dialect,
            ))
            |> string_builder.append_builder(
              w.operator_to_string(operator, dialect)
              |> wrap_string_builder(" "),
            )
            |> string_builder.append_builder(v.to_placeholder(value, dialect))
          }
        }
      }),
    "",
  ))
}

fn where_builder(where_clauses: List(Where), dialect: Dialect) -> StringBuilder {
  case where_clauses {
    [] -> string_builder.from_string("")
    _ -> where_builder_do(where_clauses, dialect)
  }
}

pub fn to_query(from blueprint: Blueprint, for dialect: Dialect) -> Query {
  case blueprint.method {
    Select -> select_builder(blueprint, dialect)
    Insert -> insert_builder(blueprint, dialect)
    Update -> update_builder(blueprint, dialect)
    Delete -> delete_builder(blueprint, dialect)
  }
}

pub fn to_sqlite(blueprint: Blueprint) -> Query {
  to_query(from: blueprint, for: dialect.SQLite)
}

pub fn to_postgres(blueprint: Blueprint) -> Query {
  to_query(from: blueprint, for: dialect.Postgres)
}

pub fn delete_builder(blueprint: Blueprint, dialect: Dialect) -> Query {
  let where = case list.is_empty(blueprint.where_clauses) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" where ")
      |> string_builder.append_builder(where_builder(
        blueprint.where_clauses,
        dialect,
      ))
  }

  let data = dict.from_list(blueprint.data)

  let sql =
    string_builder.new()
    |> string_builder.append("delete from ")
    |> string_builder.append_builder(wrap_string(
      blueprint.table,
      dialect.symbol_quote(dialect),
    ))
    |> string_builder.append_builder(where)
    |> string_builder.to_string

  Query(
    sql: sql,
    bindings: data
      |> dict.values()
      |> list.append(w.values(blueprint.where_clauses)),
  )
}

pub fn update_builder(blueprint: Blueprint, dialect: Dialect) -> Query {
  let where = case list.is_empty(blueprint.where_clauses) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" where ")
      |> string_builder.append_builder(where_builder(
        blueprint.where_clauses,
        dialect,
      ))
  }
  let data = dict.from_list(blueprint.data)
  let sql =
    string_builder.new()
    |> string_builder.append("update")
    |> string_builder.append_builder(
      wrap_string(blueprint.table, dialect.symbol_quote(dialect))
      |> wrap_string_builder(" "),
    )
    |> string_builder.append("set ")
    |> string_builder.append_builder(
      data
      |> dict.keys()
      |> list.map(fn(key) {
        dialect.wrap_column(key, dialect)
        |> string_builder.append(" = ?")
      })
      |> string_builder.join(", "),
    )
    |> string_builder.append_builder(where)
    |> string_builder.to_string

  Query(
    sql: sql,
    bindings: data
      |> dict.values()
      |> list.append(w.values(blueprint.where_clauses)),
  )
}

pub fn insert_builder(blueprint: Blueprint, dialect: Dialect) -> Query {
  let data = dict.from_list(blueprint.data)
  let sql =
    string_builder.new()
    |> string_builder.append("insert into")
    |> string_builder.append_builder(
      wrap_string(blueprint.table, dialect.symbol_quote(dialect))
      |> wrap_string_builder(" "),
    )
    |> string_builder.append_builder(
      data
      |> dict.keys()
      |> list.map(dialect.wrap_column(_, dialect))
      |> string_builder.join(", ")
      |> parenthesify,
    )
    |> string_builder.append(" values ")
    |> string_builder.append_builder(
      data
      |> dict.values()
      |> list.map(fn(_) { string_builder.from_string("?") })
      |> string_builder.join(", ")
      |> parenthesify,
    )
    |> string_builder.to_string

  Query(
    sql: sql,
    bindings: data
      |> dict.values(),
  )
}

pub fn select_builder(blueprint: Blueprint, dialect: Dialect) -> Query {
  let where = case list.is_empty(blueprint.where_clauses) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" where ")
      |> string_builder.append_builder(where_builder(
        blueprint.where_clauses,
        dialect,
      ))
  }
  let order_by = case list.is_empty(blueprint.order_by) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" order by ")
      |> string_builder.append_builder(
        blueprint.order_by
        |> list.map(order.to_string(_, dialect))
        |> string_builder.join(", "),
      )
  }
  let sql =
    string_builder.new()
    |> string_builder.append("select ")
    |> string_builder.append_builder(string_builder.join(
      blueprint.columns
        |> list.map(dialect.wrap_column(_, dialect)),
      ", ",
    ))
    |> string_builder.append(" from ")
    |> string_builder.append_builder(wrap_string(
      blueprint.table,
      dialect.symbol_quote(dialect),
    ))
    |> string_builder.append_builder(where)
    |> string_builder.append_builder(order_by)
    |> string_builder.to_string

  Query(sql: sql, bindings: w.values(blueprint.where_clauses))
}
