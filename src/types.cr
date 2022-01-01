module Agave
  alias StoredValue = String |
                      Int64 |
                      Float64 |
                      Bool |
                      Time |
                      Array(Value) |
                      Hash(String, Value) |
                      Set(Value)
  alias Value = String |
                Int64 |
                Float64 |
                Bool |
                Time |
                Array(Value) |
                Hash(String, Value) |
                Set(Value) |
                Nil

  alias Data = Hash(String, StoredValue)
  alias Expirations = Hash(String, Time)

  # Compatible with Redis's simple string. Serialized as `+value goes here\r\n`.
  record SimpleString, value : String do
    def to_resp3(io : IO)
      io << '+' << value << "\r\n"
    end
  end

  class Error < ::Exception
  end

  class ClientError < Error
    getter type
    getter message

    def initialize(@type : String, @message : String)
    end
  end
end

class String
  def to_resp3(io : IO)
    io << '$' << bytesize << "\r\n"
    io << self << "\r\n"
  end
end

struct Int
  def to_resp3(io : IO)
    io << ':' << self << "\r\n"
  end
end

struct Float
  def to_resp3(io : IO)
    io << ',' << self << "\r\n"
  end
end

struct Bool
  def to_resp3(io : IO)
    io << '#'
    if self
      io << 't'
    else
      io << 'f'
    end
    io << "\r\n"
  end
end

class Array
  def to_resp3(io : IO) : Nil
    io << '*' << size << "\r\n"
    each(&.to_resp3(io))
  end
end

class Hash
  def self.from_resp3(io : IO) : self
    if (byte_marker = io.read_byte) && !('%' === byte_marker)
      raise "Byte marker is not for a hash: #{byte_marker.chr.inspect}"
    end

    size = io.read_line.to_i
    hash = new(initial_capacity: size)
    parser = Agave::Parser.new(io)
    size.times do
      key = parser.read.as(String)
      value = parser.read

      # Agave::Data is based on how we store the data in memory, but RESP is about how we communicate it over the wire. We store it on disk in the wire format for convenience.
      {% if @type == Agave::Data %}
        case value
        when Nil
          # This should never happen, but we need to reassure the compiler
        else
          hash[key] = value
        end
      {% elsif @type == Agave::Expirations %}
        case value
        when String
          hash[key] = Time::Format::RFC_3339.parse(value)
        when Time
          hash[key] = value
        else
          raise "Invalid expirations value: #{value.inspect}"
        end
      {% else %}
        hash[key] = value
      {% end %}
    end

    hash
  end

  def to_resp3(io : IO) : Nil
    io << '%' << size << "\r\n"
    each do |(key, value)|
      key.to_resp3 io
      value.to_resp3 io
    end
  end
end

struct Set
  def to_resp3(io : IO) : Nil
    io << '~' << size << "\r\n"
    each(&.to_resp3(io))
  end
end

struct Nil
  def to_resp3(io : IO) : Nil
    io << "$-1\r\n"
  end
end

class Agave::ClientError
  def to_resp3(io : IO)
    io << '-' << type << ' ' << message << "\r\n"
  end
end

struct Time
  def to_resp3(io : IO)
    io << '@'
    to_rfc3339(io, fraction_digits: 9)
    io << "\r\n"
  end
end
