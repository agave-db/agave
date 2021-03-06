# Agave DB

An in-memory key/value store for data structures. It is partly Redis-compatible, allowing you to use the Redis CLI, but the goal is not to clone Redis.

Agave was created in response to some of the common complaints about Redis in production:

- Redis blocks all commands while processing one
  - You may have heard the refrain "Don't run `KEYS` in production"
- Expanding beyond the capacity of a single CPU core requires clustering, which is a lot more complicated
  - Redis clustering puts significant constraints on key naming
  - Cluster-mode in Redis pushes a lot of the complexity out to the client drivers, which then have to delegate that complexity to the client applications
  - Redis clustering and replication are _entirely separate concepts_
- While Redis _can_ represent data types other than just strings and arrays with RESP3, and there was a plan for Redis 6 to drop support for RESP2, the vast majority of the Redis ecosystem still depends on RESP2

Agave aims to solve these:

- Commands can choose to yield the CPU if it is potentially a long-running operation
  - For example, the `KEYS` command in Agave yields after each batch of 10k keys. If no other commands are pending, it picks right back up. In practice, incurs a 1µs latency penalty per 10k keys.
- Expanding beyond the capacity of a single CPU core will be implemented with multithreading. Agave is written in Crystal, which currently has little support for multithreading, but this project will contribute effort to improving that.
- Agave supports rich, nested data structures. Commands will be implemented to drill down into nested structures.

## Data Types

Agave supports storing and serializing all of the following data types:

- Strings
- Integers
- Floats (IEE754 double-precision)
- Booleans (true/false only)
- Timestamps
- Arrays (lists implemented as arrays) of any of these types
- Sets of any of these types
- Hashes mapping string keys to values of any of these types

All collection types (arrays, sets, and hashes) are automatically created when adding to them and deleted when the last item is removed. This avoids the need to clean them up yourself.

Other data types planned:

- Sorted sets (experimental implementation is already included in the codebase, implemented with a Red-Black tree)
- Streams

## Multithreading

Agave does not yet support multithreading, but it's being worked on. There is a locking mechanism for commands to use, but it's unnecessary in Crystal's single-threaded mode.

## Installation

### Install from source

First, you'll need to install the Crystal compiler.

```shell
git clone https://github.com/agavedb/agave
cd agave
shards build
```

## Usage

```shell
bin/agave
```

## Development

All commands have access to the following:

| Expression | Type | Description |
|-|-|-|
| `command` | `Array(Agave::Value)` | The full deserialized command array |
| `key` | `String` | The name of the key to operate on. Defaults to `command[1]`. |
| `data` | `Hash(String, Agave::Value)` | The hash containing all keys and their values |
| `expirations` | `Hash(String, Time)` | A hash which maps keys to their expiration timestamps |
| `lock(key : String)` | `Nil` | A method that acquires a lock for the given key before executing its block and releases the lock after the block completes |

### Implementing commands

To implement a new Agave command, define a file with its name in the `src/commands` directory.  For example, if you want to define an `UPCASE` command, you would create a file `src/commands/upcase.cr` with the following:

```crystal
require "../commands"

# Command: UPCASE key value
Agave::Commands.define upcase do
  # If the key has expired but the server has not swept it out yet, go ahead and
  # do that now.
  check_expired! key

  # Only operate on the key if it has a value
  if value = data[key]?
    # Can only upcase strings
    if value.is_a? String
      data[key] = value.upcase
    else
      ClientError.new("WRONGTYPE", "UPCASE must be called with a String key, but `#{key}` is a #{value.class}")
    end
  end
end
```

## Contributing

1. Fork it (<https://github.com/agavedb/agave/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Jamie Gaskins](https://github.com/jgaskins) - creator and maintainer
