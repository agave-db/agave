require "../spec_helper"

require "../../src/commands/incr"

describe Agave::Commands::INCR do
  it "creates and increments a number if it doesn't exist" do
    data = Agave::Data.new
    command = ["incr", "value"] of Agave::Value
    expirations = {} of String => Time
    incr = Agave::Commands::INCR.new(command, data, expirations, Agave::LockPool.new)

    incr.call
    data["value"].should eq 1

    incr.call
    data["value"].should eq 2
  end

  # This sort of spec will be important for supporting multithreading
  it "increments atomically" do
    data = Agave::Data.new
    command = ["incr", "value"] of Agave::Value
    expirations = {} of String => Time
    incr = Agave::Commands::INCR.new(command, data, expirations, Agave::LockPool.new)
    parallelism = 500
    iterations = 20

    done = Channel(Nil).new
    parallelism.times do
      spawn do
        iterations.times { incr.call }
      ensure
        done.send nil
      end
    end

    parallelism.times do |i|
      done.receive
    end

    data["value"].as(Agave::Number).value.should eq parallelism * iterations
  end
end
