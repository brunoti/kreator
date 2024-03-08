pub type Dialect {
  SQLite
}

pub fn symbol_quote(dialect: Dialect) -> String {
  case dialect {
    SQLite -> "`"
  }
}

pub fn string_quote(dialect: Dialect) -> String {
  case dialect {
    SQLite -> "'"
  }
}
