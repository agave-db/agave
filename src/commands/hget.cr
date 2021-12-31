require "../commands"

Agave::Commands.define hget, for: Hashes do
  if field = command[2]?
    if field.is_a? String
      hash?.try(&.[field]?)
    else
      ClientError.new("ERR", "Expected string field name for hash")
    end
  end
end
