import kreator/dialect.{type Dialect}
import kreator/utils/string.{wrap_string} as ks
import gleam/string_builder.{type StringBuilder}
import gleam/int
import gleam/string
import gleam/float
import gleam/bool

pub type Value {
  String(String)
  Int(Int)
  Float(Float)
  Bool(Bool)
}

pub fn convert(value: Value, dialect: Dialect) -> StringBuilder {
  case value {
    String(v) -> wrap_string(v, dialect.string_quote(dialect))
    Int(v) -> string_builder.from_string(int.to_string(v))
    Float(v) -> string_builder.from_string(float.to_string(v))
    Bool(v) -> string_builder.from_string(bool.to_string(v) |> string.lowercase)
  }
}

pub fn as_int(i: Int) -> Value {
  Int(i)
}

pub fn as_string(i: String) -> Value {
  String(i)
}
