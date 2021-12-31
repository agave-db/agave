require "../commands"

Agave::Commands.define type do
  case value = data[key]?
  in String
    "string"
  in Int64
    "integer"
  in Float64
    "float"
  in Bool
    "boolean"
  in Array
    "list"
  in Hash
    "hash"
  in Set
    "set"
  in Nil
    "none"
  end
end
