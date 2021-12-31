require "../commands"

Agave::Commands.define "sadd", for: Sets do
  if command.size < 3
    return ClientError.new("ERR", "Must specify at least one value")
  end

  if set = set?
    count = 0i64
    command.each within: 2..-1 do |value|
      # We return only the count of items *added* to the list
      unless set.includes? value
        set << value
        count += 1
      end
    end

    count
  else
    set = data[key] = ::Set(Value).new(initial_capacity: command.size - 2)
    command.each(within: 2..-1) { |value| set << value }
    set.size.to_i64
  end
end
