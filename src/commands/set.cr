require "../commands"

Agave::Commands.define set do
  if key && (value = command[2]?)
    lock key do
      check_expired! key

      time_offset = ->{ command[4].as(String | Int64).to_i64 }
      case command[3]?.as?(String).try(&.downcase)
      when "exat"
        expiration = Time.unix(time_offset.call)
        condition_index = 5
      when "pxat"
        expiration = Time.unix_ms(time_offset.call)
        condition_index = 5
      when "ex"
        expiration = Time.utc + time_offset.call.seconds
        condition_index = 5
      when "px"
        expiration = Time.utc + time_offset.call.milliseconds
        condition_index = 5
      when "keepttl"
        expiration = expirations[key]?
        condition_index = 4
      else
        condition_index = 3
      end

      condition = command[condition_index]?.as?(String).try(&.downcase)

      if (data.has_key?(key) && condition != "nx") || (!data.has_key?(key) && condition != "xx")
        data[key] = value

        if expiration
          expirations[key] = expiration
        else
          expirations.delete key
        end
        SimpleString.new "OK"
      end
    end
  else
    ClientError.new("ERR", "SET must, at a minimum, receive a `key` and a `value`")
  end
end
