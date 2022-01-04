require "socket"
require "log"

require "./lock_pool"
require "./commands/*"
require "./types"
require "./parser"

module Agave
  class Server
    VERSION = "0.1.0"
    Log     = ::Log.for(self)

    @lock_pool = LockPool.new
    @connections = Set(ClientConnection).new

    def self.new(
      host : String = "localhost",
      port : Int32 = 6379,
      snapshot_file = "backup.dump"
    )
      data = Data.new
      expirations = Expirations.new
      if File.exists?(snapshot_file)
        Log.info { "Loading latest snapshot from #{snapshot_file.inspect}..." }
        File.open snapshot_file do |file|
          data = Data.from_resp3(file)
          Log.info { "Data loaded." }
          expirations = Expirations.from_resp3(file)
        end
        Log.info { "Key expiration loaded." }
      end

      new(
        host: host,
        port: port,
        snapshot_file: snapshot_file,
        data: data,
        expirations: expirations,
      )
    end

    def initialize(
      @host : String,
      @port : Int32,
      @data : Data,
      @expirations : Expirations,
      @snapshot_file = "backup.dump"
    )
      @socket = TCPServer.new(@host, @port, backlog: 512)
    end

    def start
      # Expire keys
      spawn expire_loop

      # Persist data to disk
      spawn snapshot_loop

      # Log stats
      spawn do
        loop do
          sleep 1.minute
          Log.info { "Total connections: #{@connections.size}" }
        end
      end

      Log.info { "Ready for connections" }
      while client = @socket.accept
        client.sync = false

        # This was an experiment with buffers to allow large command pipelines,
        # but that may require a prohibitive amount of memory for a large
        # connection count.
        # client.send_buffer_size = 1 << 20
        # client.recv_buffer_size = 1 << 20

        # Don't set read timeout unless we can ensure we'll receive something
        # from the client at least once per timeout
        client.write_timeout = 5.seconds
        # I'm surprised the tcp_keepalive_* methods for times don't take
        # Time::Span instances.
        client.tcp_keepalive_interval = 300 # 5 minutes
        client.tcp_keepalive_idle = 30 # 30 seconds
        client.tcp_keepalive_count = 3
        client.tcp_nodelay = true

        # FIXME: This creates a 2-way dependency between the Server and the
        # ClientConnection. I don't love that.
        connection = ClientConnection.new(client, self)
        @connections << connection
        spawn connection.call
      end
    end

    def finalize
      close
    end

    def close
      @connections.each do |connection|
        close connection
      rescue ex : IO::Error
      end
      @socket.close
      @closed = true
    end

    def close(connection : ClientConnection)
      @connections.delete connection
    end

    def handle(command full_command : Array(Value), connection : ClientConnection)
      if command = full_command.first?.as?(String).try(&.downcase)
        handler = Commands::MAP.fetch(command) do
          ->(full_command : Array(Value), data : Data, expirations : Expirations, locks : LockPool) do
            ClientError.new("ERR", "Unknown command: #{command}")
          end
        end

        connection << handler.call(full_command, @data, @expirations, @lock_pool)
      else
        connection << "-ERR Must supply a command"
      end
    end

    def expire_loop
      loop do
        sleep 10.seconds
        break if @closed

        count = 0
        now = Time.utc
        @expirations.each do |key, expiry|
          if expiry < now
            Log.debug { "Expiring key: #{key.inspect}" }
            @data.delete key
            @expirations.delete key
          end

          # Don't hog the CPU
          if (count += 1) > 10_000
            sleep 500.milliseconds
            count = 0
          end
        end
      rescue ex
        # FIXME: Handle errors while expiring keys
        Log.error { "expire_loop: #{ex} - #{ex.message}" }
      end
    end

    def snapshot_loop
      loop do
        sleep 30.seconds # TODO: Make configurable

        backup_file = "backup.tmp"

        # Write to a temporary file and then overwrite the old backup with it.
        # If we write straight to the target backup file and it does not
        # complete for (for example, the server runs OOM and crashes), we
        # wouldn't have a working backup to fall back to because we would have
        # overwritten it with a broken file. With the tempfile, if we crash
        # while writing, we still have a working backup, even if it's out of
        # date.
        File.open backup_file, mode: "w" do |file|
          Log.debug { "Writing #{@data.size} keys to #{@snapshot_file}..." }
          [@data, @expirations].each(&.to_resp3(file))
        end

        File.rename backup_file, @snapshot_file
      end
    end
  end

  class ClientConnection
    getter? closed = false

    def initialize(@socket : TCPSocket, @server : Server)
    end

    def call
      # spawn do
      #   loop do
      #     sleep 500.microseconds
      #     @socket.flush
      #   end
      # rescue ex : IO::Error
      #   Log.error { "Error while flushing socket: #{ex}" }
      #   @socket.close rescue nil
      # end

      until closed?
        if command = Parser.new(@socket).read.as?(Array)
          @server.handle command, self
        end
        @socket.flush
      end
    rescue ex : IO::Error
      # Network errors are not exceptional. The client can reconnect.
    rescue ex
      Log.error { "#{ex}: #{ex.message}" }
      ex.backtrace?.try(&.each { |line| Log.error { line } })
    ensure
      # We've broken out of the loop, so we should close the socket.
      @socket.close rescue nil
      @server.close self
    end

    def <<(response)
      response.to_resp3 @socket
      self
    end

    def close
      @socket.close rescue nil
      @server.close self
      @closed = true
    end
  end
end
