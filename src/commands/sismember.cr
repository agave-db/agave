require "../commands"

Agave::Commands.define "sismember", for: Sets do
  if set = set?
    count = 0i64
    command.each within: 2..-1 do |value|
      count += 1 if set.includes? value
    end

    count
  else
    0i64
  end
end
