require "../commands"

Agave::Commands.define "scard", for: Sets do
  (set?.try(&.size) || 0i64).to_i64
end
