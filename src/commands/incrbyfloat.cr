require "../commands"

Agave::Commands.define incrbyfloat, for: Floats do
  check_expired! key

  lock key do
    if amount = command[2]?.as?(String | Float64)
      if float = float?
        data[key] = float + amount.to_f64
      else
        data[key] = amount.to_f64
      end
    else
      ClientError.new("ERR", "Must supply a float value (or a string value to convert to a float) to increment by")
    end
  end
end
