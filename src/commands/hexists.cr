require "../commands"

Agave::Commands.define hexists, for: Hashes do
  unless field = command[2]?.as?(String)
    return ClientError.new("ERR", "HEXISTS requires a field name")
  end

  if (hash = hash?) && hash.has_key?(field)
    1i64
  else
    0i64
  end
end
