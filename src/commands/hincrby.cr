require "../commands"

Agave::Commands.define hincrby, for: Hashes do
  check_expired! key

  unless field = command[2]?.as?(String)
    return ClientError.new("ERR", "Field argument must be a string")
  end

  case increment = command[3]?.as?(String | Int64)
  in Int64
    increment = increment.to_i64
  in String
    unless increment = increment.to_i64?
      return ClientError.new("ERR", "Increment argument must be an integer or a string that can be parsed to an integer")
    end
  in Nil
    return ClientError.new("ERR", "Increment argument must be an integer or a string that can be parsed to an integer")
  end

  unless hash = hash?
    hash = data[key] = Hash(String, Value) { field => 0i64 }
  end

  value = (hash[field] ||= 0i64).as(Int64)
  hash[field] = value + increment
end
