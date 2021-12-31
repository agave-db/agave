require "../commands"

Agave::Commands.define toggle do
  case value = data[key]?
  when true
    data[key] = false
  when false
    data[key] = true
  else
    ClientError.new("WRONGTYPE", "Value in #{key} must be a boolean")
  end
end
