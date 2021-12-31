require "../commands"

Agave::Commands.define incrby, for: Integers do
  check_expired! key

  if integer = integer?
    if amount = command[2]?.as?(String | Int64)
      integer += amount.to_i64
      data[key] = integer
    else
      ClientError.new("ERR", "Must supply an integer value (or a string value to convert to an integer) to increment by")
    end
  else
    if amount = command[2]?.as?(String | Int64)
      data[key] = amount.to_i64
    else
      ClientError.new("ERR", "Must supply an integer value (or a string value to convert to an integer) to increment by")
    end
  end
end
