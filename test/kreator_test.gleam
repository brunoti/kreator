import gleeunit
import kreator as k
import kreator/value as v
import kreator/where as w
import kreator/order.{Ascending, Descending}
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn sqlite_insert_test() {
  let query =
    k.table("users")
    |> k.insert([
      #("email", v.as_string("b@b.com")),
      #("name", v.as_string("Bruno")),
    ])
    |> k.to_sqlite()

  query.sql
  |> should.equal("insert into `users` (`email`, `name`) values (?, ?)")
  query.bindings
  |> should.equal([v.as_string("b@b.com"), v.as_string("Bruno")])
}

pub fn sqlite_select_without_where_test() {
  let query =
    k.table("users")
    |> k.to_sqlite()

  query.sql
  |> should.equal("select * from `users`")
}

pub fn sqlite_select_with_where_test() {
  let query =
    k.table("users")
    |> k.where_equals_string("name", "Bruno")
    |> k.where_equals("id", v.as_int(1))
    |> k.to_sqlite()

  query.sql
  |> should.equal("select * from `users` where `name` = ? and `id` = ?")
  query.bindings
  |> should.equal([v.as_string("Bruno"), v.as_int(1)])
}

pub fn sqlite_select_with_nested_where_test() {
  let query =
    k.table("users")
    |> k.where_equals("id", v.as_int(1))
    |> k.or_where(fn(where) {
      where
      |> w.and_where_equals("name", v.as_string("Bruno"))
      |> w.or_where_equals("id", v.as_int(2))
    })
    |> k.and_where(fn(where) {
      where
      |> w.and_where_equals("name", v.as_string("Carlos"))
      |> w.and_where_equals("id", v.as_int(3))
    })
    |> k.to_sqlite()

  query.sql
  |> should.equal(
    "select * from `users` where `id` = ? or (`name` = ? or `id` = ?) and (`name` = ? and `id` = ?)",
  )
  query.bindings
  |> should.equal([
    v.as_int(1),
    v.as_string("Bruno"),
    v.as_int(2),
    v.as_string("Carlos"),
    v.as_int(3),
  ])
}

pub fn sqlite_update_test() {
	let query =
		k.table("users")
		|> k.update([
			#("email", v.as_string("b@b.com")),
			#("name", v.as_string("Bruno")),
		])
		|> k.where_equals("id", v.as_int(1))
		|> k.to_sqlite()

	query.sql |> should.equal("update `users` set `email` = ?, `name` = ? where `id` = ?")
	query.bindings |> should.equal([v.as_string("b@b.com"), v.as_string("Bruno"), v.as_int(1)])
}

pub fn sqlite_delete_test() {
	let query =
		k.table("users")
		|> k.where_equals("id", v.as_int(1))
		|> k.delete()
		|> k.to_sqlite()

	query.sql |> should.equal("delete from `users` where `id` = ?")
	query.bindings |> should.equal([v.as_int(1)])
}

pub fn sqlite_select_with_order_by_test() {
  let query =
    k.table("users")
		|> k.order_by("name", Ascending)
		|> k.order_by("id", Descending)
    |> k.to_sqlite()

  query.sql
  |> should.equal("select * from `users` order by `name` asc, `id` desc") }
