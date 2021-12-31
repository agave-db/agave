require "option_parser"

require "./server"

port = 6379

OptionParser.parse ARGV do |parser|
  parser.on "--port PORT", "-p", "Use the specified port" do |port_value|
    port = port_value.to_i
  end
end

server = Agave::Server.new("0.0.0.0", port)

server.start
