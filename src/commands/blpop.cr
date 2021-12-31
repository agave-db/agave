require "../commands"

Agave::Commands.define blpop, for: Lists do
  list = nil
  list_key = nil

  if timeout = command[-1].as?(String | Int64)
    timeout = timeout.to_i64.milliseconds
  else
    return ClientError.new("ERR", "Timeout argument to BLPOP must be an integer or a string that can be parsed as an integer")
  end
  start = Time.monotonic

  while list.nil? && (Time.monotonic - start) < timeout
    command.each within: 1...-1 do |key|
      key = key.as(String)
      list_key = key

      lock key do
        if (list = data[key]?.as?(Array)) && (element = list.shift?)
          if list.empty?
            data.delete list_key
          end
          return element
        elsif list # The variable has something that isn't a list
          return ClientError.new("ERR", "Key arguments to BLPOP must be lists")
        end
      end
      list_key = nil
      list = nil
    end

    sleep 5.milliseconds
  end
end
