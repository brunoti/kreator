import kreator/utils/string.{parenthesify} as _
import gleam/string_builder.{type StringBuilder}
import gleam/list

pub type Value {
  String(String)
  Int(Int)
  Float(Float)
  Bool(Bool)
  Raw(String)
  Null
  List(List(Value))
}

pub fn to_placeholder(value: Value) -> StringBuilder {
  case value {
    Raw(v) -> string_builder.from_string(v)
    List(v) ->
      v
			|> list.map(to_placeholder)
      |> string_builder.join(", ")
      |> parenthesify
    _ -> string_builder.from_string("?")
  }
}

pub fn int(i: Int) -> Value {
  Int(i)
}

pub fn string(i: String) -> Value {
  String(i)
}

pub fn bool(i: Bool) -> Value {
  Bool(i)
}

pub fn float(i: Float) -> Value {
  Float(i)
}

pub fn list(i: List(Value)) -> Value {
  List(i)
}

pub fn raw(i: String) -> Value {
  Raw(i)
}

pub fn null() -> Value {
  Null
}
