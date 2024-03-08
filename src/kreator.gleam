import gleam/io
import gleam/list
import gleam/string_builder.{type StringBuilder}
import kreator/order.{type Direction, type Order, Ascending}
import kreator/where.{Where, type Where} as w
import kreator/value.{type Value}
import kreator/dialect.{type Dialect}
import kreator/utils/string.{wrap_string, wrap_string_builder, parenthesify}

pub type Query {
  Query(
    from: String,
    columns: List(String),
    order_by: List(Order),
    where_clauses: List(Where),
  )
}

pub fn table(table: String) -> Query {
  Query(from: table, columns: ["*"], order_by: [], where_clauses: [])
}

pub fn from(query: Query, from from: String) -> Query {
  Query(..query, from: from)
}

pub fn select(query: Query, select: List(String)) -> Query {
  Query(..query, columns: select)
}

pub fn order_by(
  query: Query,
  column column: String,
  direction direction: Direction,
) -> Query {
  Query(..query, order_by: [#(column, direction), ..query.order_by])
}

fn add_where_clause(query: Query, new_where: Where) -> Query {
  Query(..query, where_clauses: w.add(query.where_clauses, new_where))
}

pub fn where_equals(query: Query, column: String, value: Value) -> Query {
  add_where_clause(
    query,
		w.equals(column: column, value: value, where_type: w.And),
  )
}

pub fn or_where(query: Query, fun: fn() -> List(Where)) -> Query {
  Query(..query, where_clauses: w.append(query.where_clauses, fun()))
}

pub fn or_where_equals(query: Query, column: String, value: Value) -> Query {
  add_where_clause(
    query,
		w.equals(column: column, value: value, where_type: w.Or),
  )
}

pub fn where_equals_string(query: Query, column: String, value: String) -> Query {
  add_where_clause(
    query,
		w.equals(column: column, value: value.as_string(value), where_type: w.And),
  )
}

fn where_builder_do(
  where_clauses: List(Where),
  dialect: Dialect,
) -> StringBuilder {
  let where_clauses_last_index = list.length(where_clauses) - 1
  string_builder.new()
  |> string_builder.append_builder(string_builder.join(
    where_clauses
      |> list.index_map(fn(where_clause, i) {
        let has_next = list.length(where_clause.next) > 0
        let connector = case where_clauses_last_index == i && !has_next {
          True -> string_builder.new()
          False ->
            w.type_to_string(where_clause.where_type, dialect)
            |> wrap_string_builder(" ")
        }

        string_builder.from_strings([
          where_clause.column,
          " ",
          where_clause.operator,
          " ",
        ])
        |> string_builder.append_builder(value.convert(
          where_clause.value,
          dialect,
        ))
        |> string_builder.append_builder(connector)
        |> string_builder.append_builder(
          where_builder(where_clause.next, dialect)
          |> parenthesify,
        )
      }),
    "",
  ))
}

fn where_builder(
  where_clauses: List(Where),
  dialect: Dialect,
) -> StringBuilder {
  case where_clauses {
    [] -> string_builder.from_string("")
    _ -> where_builder_do(where_clauses, dialect)
  }
}

pub fn to_sqlite_string(query: Query) -> String {
  string_builder.new()
  |> string_builder.append("select ")
  |> string_builder.append_builder(string_builder.join(
    query.columns
      |> list.map(wrap_string(_, dialect.symbol_quote(dialect.SQLite))),
    ", ",
  ))
  |> string_builder.append(" from ")
  |> string_builder.append_builder(wrap_string(
    query.from,
    dialect.symbol_quote(dialect.SQLite),
  ))
  |> string_builder.append(" where ")
  |> string_builder.append_builder(
    where_builder(query.where_clauses, dialect.SQLite)
    |> parenthesify,
  )
  |> string_builder.to_string()
}

pub fn main() {
  table("users")
  |> select(["id", "name"])
  |> where_equals_string("name", "Bruno")
  |> where_equals("id", value.as_int(1))
  |> or_where_equals("id", value.as_int(2))
  |> or_where(fn() {
			w.new_where_list()
			|> w.and_where_equals("id", value.as_int(3))
		})
  |> order_by(column: "name", direction: Ascending)
  |> to_sqlite_string()
  |> io.println()
}
