import gleeunit/should
import gleam/dynamic
import gleam/list
import kreator as k
import kreator/value as v
import kreator/query.{destruct}
import kreator/sqlight as kreator_sqlight
import kreator/where as w
import sqlight

pub fn with_connection(do: fn(sqlight.Connection) -> a) -> a {
  use conn <- sqlight.with_connection(":memory:")
  let assert Ok(_) =
    sqlight.exec(
      "create table users (id integer primary key autoincrement, email text, name text)",
      conn,
    )
  do(conn)
}

pub fn sqlite_insert_test() {
  use conn <- with_connection

  let insert =
    k.table("users")
    |> k.insert([#("email", v.string("b@b.com")), #("name", v.string("Bruno"))])
    |> k.to_sqlite()

  let update =
    k.table("users")
    |> k.update([#("name", v.string("Bruno Oliveira"))])
    |> k.where(w.and_where_equals(_, "email", v.string("b@b.com")))
    |> k.to_sqlite()

  let select =
    k.table("users")
    |> k.to_sqlite()

  let assert Ok(_) = kreator_sqlight.run_nil(insert, conn)
  let assert Ok(_) = kreator_sqlight.run_nil(update, conn)
  let assert Ok(result) =
    kreator_sqlight.run(
      select,
      on: conn,
      expecting: dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string),
    )

  should.equal(list.length(result), 1)
  should.equal(result, [#(1, "b@b.com", "Bruno Oliveira")])

  Ok(Nil)
}
