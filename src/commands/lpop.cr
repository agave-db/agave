require "../commands"

Agave::Commands.define lpop, for: Lists do
  count = command[2]?.as?(String | Int64).try(&.to_i)

  if list = list?
    if count
      popped = Array(Value).new(initial_capacity: count)
      count.times { popped << list.shift? }

      popped
    else
      list.shift?
    end
  end
ensure
  if list.try(&.empty?)
    data.delete key
  end
end
