import kreator/codec.{type Codec, Codec}
import gleam/json.{type Json}
import gleam/dynamic.{type Dynamic}

pub type Article {
  Article(title: String, description: String, url: String, author: String)
}
///
/// GENERATED CODE
///
// pub fn codec() -> Codec(Article) {
//   Codec(
//     from_json: fn(json: Dynamic) -> Result(Article, List(dynamic.DecodeError)) {
//       json
//       |> dynamic.decode4(
//         Article,
//         dynamic.field("title", dynamic.string),
//         dynamic.field("description", dynamic.string),
//         dynamic.field("url", dynamic.string),
//         dynamic.field("author", dynamic.string),
//       )
//     },
//     from_db: fn(data: Dynamic) -> Result(Article, List(dynamic.DecodeError)) {
//       data
//       |> dynamic.decode4(
//         Article,
//         dynamic.element(0, dynamic.string),
//         dynamic.element(1, dynamic.string),
//         dynamic.element(2, dynamic.string),
//         dynamic.element(3, dynamic.string),
//       )
//     },
//     to_json: fn(data: Article) -> Json {
// 			json.object([
// 				#("title", json.string(data.title)),
// 				#("description", json.string(data.description)),
// 				#("url", json.string(data.url)),
// 				#("author", json.string(data.author)),
// 			])
//     },
//   )
// }
