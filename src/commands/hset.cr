require "../commands"

Agave::Commands.define hset, for: Hashes do
  unless hash = hash?
    hash = @data[key] = Hash(String, Value).new(initial_capacity: command.size // 2 - 1)
  end

  count = 0i64
  2.step(by: 2, to: command.size, exclusive: true) do |index|
    key = command[index].as(String)
    value = command[index + 1]

    unless hash.has_key? key
      count += 1
    end

    hash[key] = value
  end

  count
end
