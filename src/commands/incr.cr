require "../commands"

Agave::Commands.define incr, for: Integers do
  check_expired! key

  lock key do
    if integer = integer?
      data[key] = integer + 1
    else
      data[key] = 1i64
    end
  end
end
