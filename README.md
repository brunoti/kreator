# kreator

[![Package Version](https://img.shields.io/hexpm/v/kreator)](https://hex.pm/packages/kreator)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/kreator/)

```sh
gleam add kreator
```

This is a very wip query builder made in pure gleam to be used with multiple DB dialects.

```gleam
import kreator as k
import kreator/sqlight as ks
import kreator/where.{and_where_equals}
import kreator/value as v
import gleam/dynamic
import sqlight

pub fn main() {
    use conn <- sqlight.with_connection(":memory:")
    let assert Ok(_) = sqlight.exec(
      "create table users (id integer primary key autoincrement, email text, name text)",
      conn,
    )

    let insert_user_query =
        k.table("users")
        |> k.insert([#("email", v.string("b@b.com")), #("name", v.string("Bruno"))])
        |> k.to_sqlite()

    let select_user_query =
        k.table("users")
        |> k.where(and_where_equals(_, "id", v.int(1)))
        |> k.to_sqlite()

    let assert Ok(_) = ks.run_nil(insert_user_query, on: conn)

    let assert Ok(user) = ks.first(
        select_user_query,
        on: conn,
        expecting: dynamic.tupple3(dynamic.int, dynamic.string, dynamic.string)
    )

    io.debug(user) // #(1, "b@b.com", "Bruno")
}
```

Further documentation can be found at <https://hexdocs.pm/kreator>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

#### TODO
- [ ] add codec support generated from schema files
- [ ] add joins
- [ ] add aggregations
- [ ] add subqueries
- [ ] add pagination helpers
