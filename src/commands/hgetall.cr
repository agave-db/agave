require "../commands"

Agave::Commands.define hgetall, for: Hashes do
  hash?
end
