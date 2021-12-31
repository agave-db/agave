require "mutex"
require "log"

module Agave
  # The LockPool concept is for obtaining a lock on a key. For example, when we
  # increment a number or push to a list, the key is created with the
  # appropriate default value (0, empty array, etc) and the operation is
  # performed on that value. This isn't actually useful for a single-threaded
  # environment since fibers aren't preempted; they have to yield the CPU
  # themselves. But when we start looking at running multithreaded, we'll need
  # these locks for these scenarios.
  #
  # An incomplete list of scenarios where this may be needed:
  # - Incrementing a key that may not exist
  # - LPUSHing to a key that may not exist
  # - SETting a key with NX or XX
  @[Experimental("Acquiring locks on keys is experimental and not yet guaranteed to work in a multithreaded environment")]
  class LockPool
    Log = ::Log.for(self)
    # Should we use a pool to reduce GC pressure?
    # @pool = Set(Lock).new

    @locks = Hash(String, Lock).new

    # We need our own lock so that multiple lock requests for the same key don't
    # create multiple locks or delete one when another one began waiting for it.
    @lock = Mutex.new

    def initialize
    end

    # Acquire a lock for the given key.
    def lock(key : String)
      fiber = Fiber.current

      lock = lock do
        l = @locks.fetch(key) do
          @locks[key] = Lock.new
        end
        l.waiting!
        l
      end

      begin
        lock.synchronize { yield }
      ensure
        lock do
          if lock.done! <= 0
            @locks.delete key
          end
        end
      end
    end

    private def lock
      @lock.synchronize { yield }
    end

    # A lock that exposes how many fibers are waiting on it.
    private class Lock
      @waiting = Atomic(Int32).new(0)
      @mutex = Mutex.new

      def waiting!
        @waiting.add(1) + 1
      end

      def synchronize
        @mutex.synchronize { yield }
      end

      def done!
        @waiting.sub(1) - 1
      end
    end
  end
end
