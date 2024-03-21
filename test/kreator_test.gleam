import gleeunit
import kreator as k
import kreator/value as v
import kreator/where as w
import kreator/order.{Ascending, Descending}
import kreator/query.{destruct}
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn sqlite_insert_test() {
  let query =
    k.table("users")
    |> k.insert([#("email", v.string("b@b.com")), #("name", v.string("Bruno"))])
    |> k.returning(["id"])
    |> k.to_sqlite()

  query.sql
  |> should.equal(
    "insert into `users` (`email`, `name`) values (?, ?) returning `id`",
  )
  query.bindings
  |> should.equal([v.string("b@b.com"), v.string("Bruno")])
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
    |> k.where(fn(w) {
      w
      |> w.and_where_equals("name", v.string("Bruno"))
      |> w.and_where_equals("id", v.int(1))
    })
    |> k.to_sqlite()

  query.sql
  |> should.equal("select * from `users` where `name` = ? and `id` = ?")
  query.bindings
  |> should.equal([v.string("Bruno"), v.int(1)])
}

pub fn sqlite_select_with_nested_where_test() {
  let query =
    k.table("users")
    |> k.where(fn(w) {
      w
      |> w.and_where_equals("id", v.int(1))
    })
    |> k.or_where(fn(where) {
      where
      |> w.and_where_equals("name", v.string("Bruno"))
      |> w.or_where_equals("id", v.int(2))
    })
    |> k.and_where(fn(where) {
      where
      |> w.and_where_equals("name", v.string("Carlos"))
      |> w.and_where_equals("id", v.int(3))
    })
    |> k.to_sqlite()

  query.sql
  |> should.equal(
    "select * from `users` where `id` = ? or (`name` = ? or `id` = ?) and (`name` = ? and `id` = ?)",
  )
  query.bindings
  |> should.equal([
    v.int(1),
    v.string("Bruno"),
    v.int(2),
    v.string("Carlos"),
    v.int(3),
  ])
}

pub fn sqlite_update_test() {
  let query =
    k.table("users")
    |> k.update([#("email", v.string("b@b.com")), #("name", v.string("Bruno"))])
    |> k.where(w.and_where_equals(_, "id", v.int(1)))
    |> k.to_sqlite()

  query.sql
  |> should.equal("update `users` set `email` = ?, `name` = ? where `id` = ?")
  query.bindings
  |> should.equal([v.string("b@b.com"), v.string("Bruno"), v.int(1)])
}

pub fn sqlite_delete_test() {
  let #(query, data) =
    k.table("users")
    |> k.where(w.and_where_equals(_, "id", v.int(1)))
    |> k.delete()
    |> k.to_sqlite()
    |> destruct()

  should.equal(query, "delete from `users` where `id` = ?")
  should.equal(data, [v.int(1)])
}

pub fn sqlite_select_with_order_by_test() {
  let #(query, _) =
    k.table("users")
    |> k.order_by("name", Ascending)
    |> k.order_by("id", Descending)
    |> k.to_sqlite()
    |> destruct()

  should.equal(query, "select * from `users` order by `name` asc, `id` desc")
}

pub fn sqlite_select_with_returning_test() {
  let #(query, _) =
    k.table("users")
    |> k.order_by("name", Ascending)
    |> k.order_by("id", Descending)
    |> k.to_sqlite()
    |> destruct()

  should.equal(query, "select * from `users` order by `name` asc, `id` desc")
}
