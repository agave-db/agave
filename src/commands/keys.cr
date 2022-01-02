require "../commands"

Agave::Commands.define keys do
  now = Time.utc
  keys = %w[]

  if pattern = command.fetch(1) { "*" }.as?(String)
    pattern = pattern
      .gsub('.', "\.")
      .gsub('\\', "\\\\")
      .gsub('*', ".*")
    pattern = Regex.new("\\A#{pattern}\\z")

    count = 0i64
    data.each_key do |key|
      check_expired! key, now: now

      if key =~ pattern
        keys << key
      end

      # Don't hog the CPU
      if (count += 1) > 10_000
        Fiber.yield
        count = 0
      end
    end
  end

  keys
end
