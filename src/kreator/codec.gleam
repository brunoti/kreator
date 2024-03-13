import gleam/dynamic.{type Dynamic}
import gleam/json.{type Json}

pub type Codec(t) {
  Codec(
    to_json: fn(t) -> Json,
    from_json: fn(Dynamic) -> Result(t, List(dynamic.DecodeError)),
    from_db: fn(Dynamic) -> Result(t, List(dynamic.DecodeError)),
  )
}
