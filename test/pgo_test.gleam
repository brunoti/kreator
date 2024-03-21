import gleeunit/should
import gleam/dynamic
import gleam/io
import kreator as k
import kreator/value as v
import kreator/wrappers/pgo as kreator_pgo
import kreator/where as w
import gleam/pgo.{type Connection, default_config, Config}

pub fn with_connection(do: fn(Connection) -> a) -> a {
  let conn = pgo.connect(Config(
		..default_config(),
		user: "bruno",
	))
  let assert Ok(_) =
    pgo.execute(
      "DROP TABLE IF EXISTS users;",
      on: conn,
			expecting: dynamic.dynamic,
			with: []
    )
  let assert Ok(_) =
    pgo.execute(
      "
			CREATE TABLE IF NOT EXISTS users (
				id SERIAL PRIMARY KEY,
				email TEXT UNIQUE NOT NULL,
				name TEXT NOT NULL
			);
		",
      on: conn,
			expecting: dynamic.dynamic,
			with: []
    )
  let res = do(conn)
  let assert Ok(_) =
    pgo.execute(
      "DROP TABLE IF EXISTS users;",
      on: conn,
			expecting: dynamic.dynamic,
			with: []
    )
	pgo.disconnect(conn)
	res
}

pub fn pgo_insert_test() {
  use conn <- with_connection

  let insert =
    k.table("users")
    |> k.insert([#("email", v.string("b@b.com")), #("name", v.string("Bruno"))])
    |> k.to_postgres()

  let update =
    k.table("users")
    |> k.update([#("name", v.string("Bruno Oliveira"))])
    |> k.where(w.and_where_equals(_, "email", v.string("b@b.com")))
    |> k.to_postgres()

  let select =
    k.table("users")
    |> k.to_postgres()

  let assert Ok(_) = kreator_pgo.run_nil(insert, conn)

  let assert Ok(_) = kreator_pgo.run_nil(update, conn)
  let assert Ok(result) =
    kreator_pgo.run(
      select,
      on: conn,
      expecting: dynamic.tuple3(dynamic.int, dynamic.string, dynamic.string),
    )

  should.equal(result.count, 1)
  should.equal(result.rows, [#(1, "b@b.com", "Bruno Oliveira")])

  Ok(Nil)
}
