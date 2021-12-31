require "../commands"

Agave::Commands.define ttl do
  if expiry = expirations[key]?
    ttl = (expiry - Time.utc).total_seconds.to_i
    if ttl >= 0
      ttl
    else
      data.delete key
      expirations.delete key
      nil
    end
  end
end
