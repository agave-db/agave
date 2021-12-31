require "../commands"

Agave::Commands.define ping do
  command.fetch(1) { SimpleString.new "PONG" }
end
