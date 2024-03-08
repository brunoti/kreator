import gleam/io
import gleam/list
import gleam/result as r
import gleam/string_builder.{type StringBuilder}
import kreator/order.{type Direction, type Order, Ascending}
import kreator/where.{Where, type Where} as w
import kreator/value.{type Value}
import kreator/dialect.{type Dialect}
import gleam/dict
import kreator/utils/string.{wrap_string, wrap_string_builder, parenthesify}

pub type Query {
  Query(
    table: String,
    columns: List(String),
    order_by: List(Order),
    where_clauses: List(Where),
    insert: List(#(String, Value)),
  )
}

pub fn table(table: String) -> Query {
  Query(table: table, columns: ["*"], order_by: [], where_clauses: [], insert: [])
}

pub fn select(query: Query, select: List(String)) -> Query {
  Query(..query, columns: select)
}

pub fn insert(query: Query, data: List(#(String, Value))) -> Query {
	Query(..query, insert: data)
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

				let after = case where_clauses_last_index != i && has_next {
					True -> list.last(where_clause.next) |> r.map(w.where_type) |> r.unwrap(w.And) |> w.type_to_string(dialect) |> wrap_string_builder(" ")
					False -> string_builder.new()
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
				|> string_builder.append_builder(after)
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
	case query.insert {
		[] -> select_builder(query, dialect.SQLite)
		_ -> insert_builder(query, dialect.SQLite)
	}
}


pub fn insert_builder(query: Query, dialect: Dialect) -> String {
	let data = dict.from_list(query.insert)
  string_builder.new()
		|> string_builder.append("insert into")
		|> string_builder.append_builder(wrap_string(
			query.table,
			dialect.symbol_quote(dialect),
		) |> wrap_string_builder(" "))
		|> string_builder.append_builder(
				data |> dict.keys() |> list.map(wrap_string(_, dialect.symbol_quote(dialect))) |> string_builder.join(", ") |> parenthesify
			)
		|> string_builder.append(" values ")
		|> string_builder.append_builder(
			data |> dict.values() |> list.map(value.convert(_, dialect)) |> string_builder.join(", ") |> parenthesify
		)
		|> string_builder.to_string()
}

pub fn select_builder(query: Query, dialect: Dialect) -> String {
  string_builder.new()
  |> string_builder.append("select ")
  |> string_builder.append_builder(string_builder.join(
    query.columns
      |> list.map(wrap_string(_, dialect.symbol_quote(dialect))),
    ", ",
  ))
  |> string_builder.append(" from ")
  |> string_builder.append_builder(wrap_string(
    query.table,
    dialect.symbol_quote(dialect),
  ))
  |> string_builder.append(" where ")
  |> string_builder.append_builder(
    where_builder(query.where_clauses, dialect)
    |> parenthesify,
  )
  |> string_builder.to_string()
}

pub fn main() {
  io.println("")
  io.println("SELECT:")
  table("users")
  |> select(["id", "name"])
  |> where_equals_string("name", "Bruno' AND public = 1")
  |> where_equals("id", value.as_int(1))
  |> or_where_equals("id", value.as_int(2))
  |> or_where(fn() {
			w.new_where_list()
			|> w.and_where_equals("id", value.as_int(3))
			|> w.or_where_equals("id", value.as_int(4))
		})
  |> where_equals("id", value.as_int(5))
  |> where_equals("id", value.as_int(5))
  |> or_where(fn() {
			w.new_where_list()
			|> w.and_where_equals("id", value.as_int(3))
			|> w.and_where_equals("id", value.as_int(4))
		})
  |> order_by(column: "name", direction: Ascending)
  |> to_sqlite_string()
  |> io.println()

  io.println("")
	io.println("INSERT:")
	table("users")
	|> insert([
		#("name", value.as_string("Bruno")),
		#("public", value.as_int(1)),
	])
	|> to_sqlite_string()
  |> io.println()
}
