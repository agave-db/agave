require "../commands"

Agave::Commands.define "smembers", for: Sets do
  if set = set?
    set
  else
    ::Set(Value).new
  end
end
