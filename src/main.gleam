import gleam/io
import gleam/json
import gleam/list
import gleam/result.{try} as r
import gleam/dynamic
import glance
import simplifile.{read}

pub fn main() {
  use file <- try(
    read("./src/schemas/article.gleam")
    |> r.replace_error(Nil),
  )
  use file <- try(
    glance.module(file)
    |> r.replace_error(Nil),
  )
  use schema <- try(
    file.custom_types
    |> list.first(),
  )
  io.debug(schema.definition.variants)
  Ok(Nil)
}
