import kreator/query.{type Query}
import gleam/dynamic.{type Decoder}
import gleam/list
import gleam/result.{try}
import kreator/value.{type Value, Bool, Float, Int, List, Null, Raw, String}
import sqlight.{SqlightError}

fn convert_values(values: List(Value)) -> List(sqlight.Value) {
  list.flat_map(values, fn(value) {
    case value {
      String(v) -> [sqlight.text(v)]
      Int(v) -> [sqlight.int(v)]
      Float(v) -> [sqlight.float(v)]
      Bool(v) -> [sqlight.bool(v)]
      Raw(v) -> [sqlight.text(v)]
      List(list) -> convert_values(list)
      Null -> [sqlight.null()]
    }
  })
}

pub fn run(
  query: Query,
  on conn: sqlight.Connection,
  expecting dynamic: Decoder(t),
) -> Result(List(t), sqlight.Error) {
  sqlight.query(
    query.sql,
    with: convert_values(query.bindings),
    on: conn,
    expecting: dynamic,
  )
}

pub fn run_nil(
  query: Query,
  on conn: sqlight.Connection,
) -> Result(Nil, sqlight.Error) {
  sqlight.query(
    query.sql,
    with: convert_values(query.bindings),
    on: conn,
    expecting: dynamic.dynamic,
  )
  |> result.map(fn(_) { Nil })
}

pub fn first(
  query: Query,
  on conn: sqlight.Connection,
  expecting dynamic: Decoder(t),
) -> Result(t, sqlight.Error) {
  use result <- try(sqlight.query(
    query.sql,
    with: convert_values(query.bindings),
    on: conn,
    expecting: dynamic,
  ))
  result
  |> list.first()
  |> result.replace_error(SqlightError(
    code: sqlight.GenericError,
    message: "No rows in result set",
    offset: -1,
  ))
}
