require "../commands"

Agave::Commands.define hdel, for: Hashes do
  if hash = hash?
    count = 0

    command.each within: 2.. do |field|
      if hash.has_key? field
        hash.delete field
        count += 1
      end
    end

    count
  else
    0i64
  end
end
