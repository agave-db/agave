require "../commands"

Agave::Commands.define hkeys, for: Hashes do
  if hash = hash?
    hash.keys
  else
    [] of Value
  end
end
