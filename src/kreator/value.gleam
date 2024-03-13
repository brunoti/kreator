import kreator/dialect.{type Dialect}
import kreator/utils/string.{parenthesify, wrap_string} as _
import gleam/string_builder.{type StringBuilder}
import gleam/int
import gleam/string
import gleam/list
import gleam/float
import gleam/bool
import sqlight

pub type Value {
  String(String)
  Int(Int)
  Float(Float)
  Bool(Bool)
  Raw(String)
  Null
  List(List(Value))
}

pub fn to_placeholder(value: Value, dialect: Dialect) -> StringBuilder {
  case value {
    Raw(v) -> string_builder.from_string(v)
    Null -> string_builder.from_string("null")
    List(v) ->
      v
      |> list.map(to_placeholder(_, dialect))
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
