require "../commands"

Agave::Commands.define hmget, for: Hashes do
  if hash = hash?
    Array.new(command.size - 2) do |i|
      hash[command[i + 2].as(String)]?
    end
  else
    # TODO: This can be optimized by not actually creating the array.
    Array.new(command.size - 2) { nil }
  end
end
