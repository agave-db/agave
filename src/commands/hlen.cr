require "../commands"

Agave::Commands.define hlen, for: Hashes do
  if hash = hash?
    hash.size
  else
    0i64
  end
end
