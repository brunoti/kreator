import kreator/value.{type Value}

pub type Query {
  Query(sql: String, bindings: List(Value))
}

pub fn get_sql(query: Query) -> String {
	query.sql
}
