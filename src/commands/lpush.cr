require "../commands"

Agave::Commands.define "lpush", for: Lists do
  list = list? || (data[key] = Array(Value).new(initial_capacity: 1))

  command.each(within: 2..-1) { |value| list << value }

  list.size.to_i64
end
