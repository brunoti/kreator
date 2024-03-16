import gleam/list
import gleam/dict
import gleam/string_builder.{type StringBuilder}
import kreator/order.{type Direction, type Order}
import kreator/where.{type Where, WhereBasic, WhereWrapped} as w
import kreator/value.{type Value} as v
import kreator/dialect.{type Dialect}
import kreator/query.{type Query, Query}
import kreator/utils/string.{parenthesify, wrap_string, wrap_string_builder} as _

///
/// The method of the query.
/// This is what defines if the query is a select, insert, update, or delete.
///
pub opaque type Method {
  Select
  Insert
  Update
  Delete
}

///
/// The plan of the query. Contains all the instructions needed to build a query string.
///
pub opaque type Plan {
  Plan(
    method: Method,
    table: String,
    columns: List(String),
    order_by: List(Order),
    where_clauses: List(Where),
    data: List(#(String, Value)),
  )
}

///
/// Start a new plan to build a query by setting the table. With just using this
/// you can already create a simple select like this:
///
///```gleam
/// table("users") |> to_sqlite() /// ==> "select * from `users`"
///```
/// If you want to know how to select specific columns you can jump to the [select](#select) function.
///
///
pub fn table(table: String) -> Plan {
  Plan(
    table: table,
    columns: ["*"],
    order_by: [],
    where_clauses: [],
    data: [],
    method: Select,
  )
}

///
/// Set the columns on a select statement. By default the value is `["*"]`.
///
///```gleam
/// table("users") |> select(['name', ['id']]) |> to_sqlite() /// ==> "select `name`, `id` from `users`"
///```
///
pub fn select(plan: Plan, select: List(String)) -> Plan {
  Plan(..plan, columns: select, method: Select)
}

///
/// Transforms the plan into an insert query and sets the data to be inserted.
/// It will not fail if the data is empty, tough the generated query will
/// probably be invalid.
///
/// <details>
/// <summary>Example</summary>
///
///	import kreator.{table, insert, to_sqlite}
///
///	pub fn insert_users() {
///	  table("users")
///	  |> insert([("name", "Bruno")])
///	  |> to_sqlite()
///	  /// ==> "insert into `users` (`name`) values (?)"
///	}
////<details>
pub fn insert(plan: Plan, data: List(#(String, Value))) -> Plan {
  Plan(..plan, data: data, method: Insert)
}

///
/// Transforms the plan into an unpdate query and sets the data to be updated.
/// It will not fail if the data is empty, tough the generated query will
/// probably be invalid. Also it will not fail if no where was set.
///
pub fn update(plan: Plan, data: List(#(String, Value))) -> Plan {
  Plan(..plan, data: data, method: Update)
}

///
/// Transforms the plan into a delete query. Will not fail if no where was set.
///
pub fn delete(plan: Plan) -> Plan {
  Plan(..plan, method: Delete)
}

///
/// Add an order by clause to the plan. Can be used multiple times to add
/// multiple order by clauses.
///
pub fn order_by(
  plan: Plan,
  column column: String,
  direction direction: Direction,
) -> Plan {
  Plan(
    ..plan,
    order_by: list.append(plan.order_by, [#(column, direction)]),
  )
}

///
/// Used to add where clauses to the plan. Receives a function where the
/// parameter is the current list of where clauses and it should return
/// the new where clauses. OBS.: those clauses will be unwrapped.
///
pub fn where(
  plan: Plan,
  fun: fn(List(Where)) -> List(Where),
) -> Plan {
  Plan(..plan, where_clauses: fun(plan.where_clauses))
}

///
/// Used to add where clauses to the plan. Receives a function where the
/// parameter is a new empty list of where clauses and it should return
/// a list clauses. The difference from [where](#where) and
/// [or_where](#or_where) is that this function will
/// generate wrapped where clauses with `AND`.
///
pub fn and_where(
  plan: Plan,
  fun: fn(List(Where)) -> List(Where),
) -> Plan {
  Plan(
    ..plan,
    where_clauses: w.add(
      plan.where_clauses,
      WhereWrapped(w.And, fun(w.new_where_list())),
    ),
  )
}

///
/// Used to add where clauses to the plan. Receives a function where the
/// parameter is a new empty list of where clauses and it should return
/// a list clauses. The difference from [where](#where) and
/// [and_where](#and_where) is that this function will
/// generate wrapped where clauses with `Or`.
///
pub fn or_where(
  plan: Plan,
  fun: fn(List(Where)) -> List(Where),
) -> Plan {
  Plan(
    ..plan,
    where_clauses: w.add(
      plan.where_clauses,
      WhereWrapped(w.Or, fun(w.new_where_list())),
    ),
  )
}

///
/// Builds a query based on a `Plan` for the SQLite dialect.
///
pub fn to_sqlite(plan: Plan) -> Query {
  to_query(from: plan, for: dialect.SQLite)
}

///
/// Builds a query based on a `Plan` for the `Postgres`` dialect.
///
pub fn to_postgres(plan: Plan) -> Query {
  to_query(from: plan, for: dialect.Postgres)
}

/// ------------------------------
/// ---------- BUILDERS ----------
/// ------------------------------

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

fn to_query(from plan: Plan, for dialect: Dialect) -> Query {
  case plan.method {
    Select -> select_builder(plan, dialect)
    Insert -> insert_builder(plan, dialect)
    Update -> update_builder(plan, dialect)
    Delete -> delete_builder(plan, dialect)
  }
}

fn delete_builder(plan: Plan, dialect: Dialect) -> Query {
  let where = case list.is_empty(plan.where_clauses) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" where ")
      |> string_builder.append_builder(where_builder(
        plan.where_clauses,
        dialect,
      ))
  }

  let data = dict.from_list(plan.data)

  let sql =
    string_builder.new()
    |> string_builder.append("delete from ")
    |> string_builder.append_builder(wrap_string(
      plan.table,
      dialect.symbol_quote(dialect),
    ))
    |> string_builder.append_builder(where)
    |> string_builder.to_string

  Query(
    sql: sql,
    bindings: data
      |> dict.values()
      |> list.append(w.values(plan.where_clauses)),
  )
}

fn update_builder(plan: Plan, dialect: Dialect) -> Query {
  let where = case list.is_empty(plan.where_clauses) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" where ")
      |> string_builder.append_builder(where_builder(
        plan.where_clauses,
        dialect,
      ))
  }
  let data = dict.from_list(plan.data)
  let sql =
    string_builder.new()
    |> string_builder.append("update")
    |> string_builder.append_builder(
      wrap_string(plan.table, dialect.symbol_quote(dialect))
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
      |> list.append(w.values(plan.where_clauses)),
  )
}

fn insert_builder(plan: Plan, dialect: Dialect) -> Query {
  let data = dict.from_list(plan.data)
  let sql =
    string_builder.new()
    |> string_builder.append("insert into")
    |> string_builder.append_builder(
      wrap_string(plan.table, dialect.symbol_quote(dialect))
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

fn select_builder(plan: Plan, dialect: Dialect) -> Query {
  let where = case list.is_empty(plan.where_clauses) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" where ")
      |> string_builder.append_builder(where_builder(
        plan.where_clauses,
        dialect,
      ))
  }
  let order_by = case list.is_empty(plan.order_by) {
    True -> string_builder.from_string("")
    False ->
      string_builder.from_string(" order by ")
      |> string_builder.append_builder(
        plan.order_by
        |> list.map(order.to_string(_, dialect))
        |> string_builder.join(", "),
      )
  }
  let sql =
    string_builder.new()
    |> string_builder.append("select ")
    |> string_builder.append_builder(string_builder.join(
      plan.columns
        |> list.map(dialect.wrap_column(_, dialect)),
      ", ",
    ))
    |> string_builder.append(" from ")
    |> string_builder.append_builder(wrap_string(
      plan.table,
      dialect.symbol_quote(dialect),
    ))
    |> string_builder.append_builder(where)
    |> string_builder.append_builder(order_by)
    |> string_builder.to_string

  Query(sql: sql, bindings: w.values(plan.where_clauses))
}
