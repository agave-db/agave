require "../commands"

Agave::Commands.define pttl do
  if expiry = expirations[key]?
    ttl = (expiry - Time.utc).total_milliseconds.to_i
    if ttl >= 0
      ttl
    else
      @data.delete key
      @expirations.delete key
      nil
    end
  end
end
