require "../commands"

Agave::Commands.define get do
  check_expired! key

  data[key]?
end
