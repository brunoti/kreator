import kreator/query.{type Query}
import gleam/dynamic.{type Decoder}
import gleam/list
import gleam/result
import kreator/value.{type Value, Bool, Float, Int, List, Null, Raw, String}
import gleam/pgo.{type QueryError, type Connection, type Returned}

fn convert_values(values: List(Value)) -> List(pgo.Value) {
  list.flat_map(values, fn(value) {
    case value {
      String(v) -> [pgo.text(v)]
      Int(v) -> [pgo.int(v)]
      Float(v) -> [pgo.float(v)]
      Bool(v) -> [pgo.bool(v)]
      Raw(v) -> [pgo.text(v)]
      List(list) -> convert_values(list)
      Null -> [pgo.null()]
    }
  })
}

pub fn run(
  query: Query,
  on conn: Connection,
  expecting dynamic: Decoder(t),
) -> Result(Returned(t), QueryError) {

  pgo.execute(
    query.sql,
    with: convert_values(query.bindings),
    on: conn,
    expecting: dynamic,
  )
}

pub fn run_nil(
  query: Query,
  on conn: Connection,
) -> Result(Nil, QueryError) {
  pgo.execute(
    query.sql,
    with: convert_values(query.bindings),
    on: conn,
    expecting: dynamic.dynamic,
  )
  |> result.map(fn(_) { Nil })
}
