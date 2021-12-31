require "../commands"

Agave::Commands.define exists do
  count = 0
  command.each within: 1.. do |key|
    count += 1 if data.has_key? key.as(String)
  end

  count
end
