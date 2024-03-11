# kreator

[![Package Version](https://img.shields.io/hexpm/v/kreator)](https://hex.pm/packages/kreator)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/kreator/)

```sh
gleam add kreator
```

This is a very wip query builder made in pure gleam to be used with multiple DB dialects.

```gleam
import kreator as k
import sqlight

pub fn main() {
    use conn <- sqlight.with_connection(":memory:")
    let query = k.table("articles") |> k.to_sqlite()
    sqlight.query(
        query.sql,
        on: conn,
        with: [],
        expecting: decoder(),
    )
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
