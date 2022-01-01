require "./spec_helper"

require "../src/parser"

module Agave
  describe Parser do
    it "reads ints" do
      [1, 12, 1234, 12345678, 123456789012345678_i64, -1, -12345678, 0].each do |int|
        io = IO::Memory.new(":#{int}\r\n")
        Parser.new(io).read.should eq int
      end
    end

    it "reads simple strings" do
      io = IO::Memory.new("+OK\r\n")
      Parser.new(io).read.should eq "OK"
    end

    it "reads bulk strings" do
      io = IO::Memory.new("$11\r\nHello world\r\n")
      Parser.new(io).read.should eq "Hello world"

      io = IO::Memory.new("$0\r\n\r\n")
      Parser.new(io).read.should eq ""
    end

    it "reads nil" do
      io = IO::Memory.new("$-1\r\n")
      Parser.new(io).read.should eq nil

      io = IO::Memory.new("*-1\r\n")
      Parser.new(io).read.should eq nil
    end

    it "reads arrays" do
      io = IO::Memory.new
      io << "*3\r\n"
      io << "$4\r\n" # Bulk string, length 4
      io << "foo!\r\n" # Value of that bulk string
      io << ":12345\r\n" # Int value 12345
      io << "$-1\r\n" # nil

      Parser.new(io.rewind).read.should eq ["foo!", 12345, nil]
    end

    it "reads hashes" do
      io = IO::Memory.new
      io << "%2\r\n"
      io << "+first\r\n"
      io << ":1\r\n"
      io << "+second\r\n"
      io << ":2\r\n"
      io << ":123\r\n"

      parser = Parser.new(io.rewind)
      parser.read.should eq({"first" => 1, "second" => 2})
      parser.read.should eq 123
    end

    it "reads nil" do
      io = IO::Memory.new
      io << "_\r\n"

      Parser.new(io.rewind).read.should be_nil
    end

    it "reads floats" do
      io = IO::Memory.new
      io << ",1.23\r\n"
      io << ",inf\r\n"
      io << ",-inf\r\n"
      io << ",1.2345E2\r\n"
      io << ",1.2345E-2\r\n"

      parser = Parser.new(io.rewind)
      parser.read.should eq 1.23
      parser.read.should eq Float64::INFINITY
      parser.read.should eq -Float64::INFINITY
      parser.read.should eq 123.45
      parser.read.should eq 0.012345
    end

    it "reads booleans" do
      io = IO::Memory.new
      io << "#t\r\n"
      io << "#f\r\n"

      parser = Parser.new(io.rewind)
      parser.read.should eq true
      parser.read.should eq false
    end

    it "reads floats" do
      io = IO::Memory.new
      io << "@2021-12-31T23:59:29.123456789Z\r\n"
      io << "@2022-01-23T12:34:56.987654321Z\r\n"

      timestamp = Parser.new(io.rewind).read.as(Time)

      timestamp.year.should eq 2021
      timestamp.month.should eq 12
      timestamp.day.should eq 31
      timestamp.hour.should eq 23
      timestamp.minute.should eq 59
      timestamp.second.should eq 29
      timestamp.nanosecond.should eq 123456789
      timestamp.location.name.should eq "UTC"

      timestamp = Parser.new(io).read.as(Time)

      timestamp.should eq Time::Format::RFC_3339.parse("2022-01-23T12:34:56.987654321Z")
    end

    it "reads verbatim strings" do
      io = IO::Memory.new
      io << "=15\r\n"
      io << "txt:Some string\r\n"

      parser = Parser.new(io.rewind)
      parser.read.should eq "Some string"
    end

    it "reads sets" do
      io = IO::Memory.new
      io << "~5\r\n"
      io << "+orange\r\n"
      io << "+apple\r\n"
      io << "#t\r\n"
      io << ":100\r\n"
      io << ":999\r\n"

      parser = Parser.new(io.rewind)
      parser.read.should eq Set{"orange", "apple", true, 100i64, 999i64}
    end
  end
end
