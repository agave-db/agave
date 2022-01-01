require "./types"

module Agave
  struct Parser
    # Initialize a parser to read from the given IO
    def initialize(@io : IO)
    end

    # Read an `Agave::Value` from the parser's `IO`
    #
    # Example:
    #
    # ```
    # io = IO::Memory.new
    # io << "$3\r\n"
    # io << "foo\r\n"
    # io.rewind
    #
    # Parser.new(io).read # => "foo"
    # ```
    def read : Value
      case byte_marker = @io.read_byte
      when ':'
        parse_int.tap { crlf }
      when '*'
        read_array
      when '$'
        read_string
      when '+'
        @io.read_line
      when '@'
        read_timestamp
      when '%'
        read_map
      when '_'
        crlf
        nil
      when ','
        read_double
      when '#'
        read_boolean
      when '='
        read_verbatim_string
      when '~'
        read_set
      when '-'
        type, message = @io.read_line.split(' ', 2)
        raise Error.new("#{type} #{message}")
      when nil
        raise IO::Error.new("Connection closed")
      else
        raise "Invalid byte marker: #{byte_marker.chr.inspect}"
      end
    end

    def read_array
      length = parse_int
      crlf
      if length >= 0
        Array.new(length) { read }
      end
    end

    def read_map
      size = parse_int
      crlf
      map = Hash(String, Value).new(initial_capacity: size)
      size.times do
        map[read.as(String)] = read
      end
      map
    end

    def read_set
      size = parse_int
      crlf
      set = Set(Value).new(initial_capacity: size)

      size.times { set << read }

      set
    end

    def read_string
      length = parse_int
      crlf
      if length >= 0
        value = @io.read_string length
        crlf
        value
      end
    end

    def read_double
      @io.read_line.to_f
    end

    def read_boolean
      case byte = @io.read_byte
      when 't'
        boolean = true
      when 'f'
        boolean = false
      when nil
        raise IO::Error.new("Connection closed")
      else
        raise Error.new("Unknown boolean: #{byte.chr.inspect}")
      end
      crlf
      boolean
    end

    def read_timestamp
      # YYYY-MM-DDTHH:MM:SS.NNNNNNNNNZ
      year = parse_int.to_i32
      @io.skip 1 #
      month = parse_int.to_i32
      @io.skip 1
      day = parse_int.to_i32
      @io.skip 1
      hour = parse_int.to_i32
      @io.skip 1
      minute = parse_int.to_i32
      @io.skip 1
      second = parse_int.to_i32
      @io.skip 1
      nanosecond = parse_int.to_i32
      # IO#read_line will allocate a string on the heap, but we want to avoid
      # that if we can, so we'll just skip to the end byte by byte.
      until '\n' === @io.read_byte
      end

      Time.utc(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        nanosecond: nanosecond,
      )
    end

    def read_verbatim_string
      size = parse_int
      crlf
      @io.skip 4                # "txt:" or "mkd:"
      @io.read_string(size - 4) # size includes the bytes we skipped
    end

    def read_attributes
      @attributes.merge! read_map.as(Map)
      read
    end

    private def parse_int
      int = 0i64
      negative = false
      has_read = false
      loop do
        if peek = @io.peek
          case next_byte = peek[0]
          when nil
            break
          when '-'
            break if has_read
            negative = true
            @io.skip 1
          when '0'.ord..'9'.ord
            int = (int * 10) + (next_byte - '0'.ord)
            @io.skip 1
          else
            break
          end
        else
          break
        end

        has_read = true
      end

      if negative
        -int
      else
        int
      end
    end

    def crlf
      @io.skip 2
    end
  end
end
