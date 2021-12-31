require "./spec_helper"
require "redis"

require "../src/server"

describe Agave::Server do
  port = rand(50_000..60_000)
  server = Agave::Server.new("localhost", port)
  before_all { spawn server.start }
  after_all { server.close }

  it "sets values for keys" do
    redis = Agave::Client.new(URI.parse("redis://:#{port}/"))

    redis.set "foo", "bar"

    redis.get("foo").should eq "bar"
  end
end
