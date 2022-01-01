require "../commands"

Agave::Commands.define toggle do
  if new_value = command[2]?.as?(String | Bool)
    data[key] = case new_value
                when Bool
                  new_value
                when "true", "t"
                  true
                when "false", "f"
                  false
                else
                  return ClientError.new("ERR", "The new value passed to TOGGLE must be a boolean or a string value that can be parsed as a boolean")
                end
  else
    case value = data[key]?
    when true
      data[key] = false
    when false, nil
      data[key] = true
    else
      ClientError.new("WRONGTYPE", "Value in #{key} must be a boolean")
    end
  end
end
