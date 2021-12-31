require "../commands"

Agave::Commands.define "lrange", for: Lists do
  unless (start = command[2].as?(String).try(&.to_i)) && (stop = command[3].as?(String).try(&.to_i))
    return ClientError.new("ERR", "Must supply start and stop list indexes")
  end

  if list = list?
    list[start..stop]
  else
    [] of Value
  end
end
