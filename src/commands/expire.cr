require "../commands"

Agave::Commands.define expire do
  if seconds = command[2]?.as?(String).try(&.to_i64)
    if data.has_key? key
      expirations[key] = seconds.seconds.from_now
      1i64
    else
      0i64
    end
  else
    ClientError.new("ERR", "Must supply expiration time in seconds")
  end
end
