require "../commands"

Agave::Commands.define flushdb do
  data.clear
  expirations.clear

  SimpleString.new "OK"
end
