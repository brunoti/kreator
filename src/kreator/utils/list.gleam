import gleam/list

pub fn head(list: List(a)) -> List(a) {
  list.take(list, list.length(list) - 1)
}
