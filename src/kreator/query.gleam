import kreator/value.{type Value}

pub type Query {
  Query(sql: String, bindings: List(Value))
}

pub fn destruct(query: Query) -> #(String, List(Value)) {
	#(query.sql, query.bindings)
}
