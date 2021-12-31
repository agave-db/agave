require "./types"
require "./lock_pool"

module Agave
  module Commands
    MAP = Hash(String, Command.class).new

    abstract struct Command
      abstract def call

      getter command : Array(Value)
      getter data : Data
      getter expirations : Expirations
      @locks : LockPool

      def self.call(command : Array(Value), data : Data, expirations : Expirations, locks : LockPool)
        new(command, data, expirations, locks).call
      rescue ex
        ClientError.new("ERR", ex.message || "")
      end

      def initialize(@command, @data, @expirations, @locks)
      end

      macro inherited
        register_command {{@type.id.gsub(/\A.*:/, "").id}}
      end

      macro register_command(command)
        def self.command_name
          {{command.id.stringify.downcase}}
        end

        ::Agave::Commands::MAP[command_name] = self
      end

      def check_expired!(*keys : String, now : Time = Time.utc)
        keys.each do |key|
          if (expiry = expirations[key]?) && expiry < now
            data.delete key
            expirations.delete key
          end
        end
      end

      @[Experimental("Acquiring locks on keys is experimental and not guaranteed to work in a multithreaded environment")]
      def lock(key : String)
        @locks.lock(key) { yield }
      end

      def key
        if key = command[key_index]?.as?(String)
          key
        else
          raise "Syntax error"
        end
      end

      def key_index
        1
      end
    end

    abstract struct Sets < Command
      def set? : ::Set(Value)?
        if set = data[key]?
          if set.is_a? ::Set
            set
          else
            raise ClientError.new("WRONGTYPE", "Can only #{self.class.command_name} a Set key. #{key.inspect} contains a #{set.class.name}.")
          end
        end
      end
    end

    abstract struct Lists < Command
      def list? : Array(Value)?
        if list = data[key]?
          if list.is_a? Array
            list
          else
            raise ClientError.new("WRONGTYPE", "Can only #{self.class.command_name} a Set key. #{key.inspect} contains a #{list.class.name}.")
          end
        end
      end
    end

    abstract struct Integers < Command
      def integer? : Int64?
        if integer = data[key]?
          if integer.is_a? Int64
            integer
          else
            raise ClientError.new("WRONGTYPE", "Can only #{self.class.command_name} an Integer key. #{key.inspect} contains a #{integer.class.name}.")
          end
        end
      end
    end

    abstract struct Floats < Command
      def float? : Float64?
        if float = data[key]?
          if float.is_a? Float64
            float
          else
            raise ClientError.new("WRONGTYPE", "Can only #{self.class.command_name} a Float key. #{key.inspect} contains a #{float.class.name}.")
          end
        end
      end
    end

    abstract struct Hashes < Command
      def hash? : Hash(String, Value)?
        if hash = data[key]?
          if hash.is_a? Hash
            hash
          else
            raise ClientError.new("WRONGTYPE", "Can only #{self.class.command_name} a Hash key. #{key.inspect} contains a #{hash.class.name}.")
          end
        end
      end
    end

    macro define(command, for type = Command, key_index = 1)
      module ::Agave::Commands
        struct {{command.id.upcase}} < {{type}}
          def call
            {{yield}}
          end
        end
      end
    end
  end
end
