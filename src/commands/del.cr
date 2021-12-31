require "../commands"

Agave::Commands.define del do
  count = 0i64
  command.each within: 1.. do |key|
    if @data.has_key? key
      @data.delete key
      count += 1
    else
      0i64
    end
  end

  count
end
