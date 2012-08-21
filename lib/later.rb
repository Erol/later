require 'later/version'
require 'redis'
require 'nest'

module Later
  class Schedule
    def key
      @key
    end

    def initialize(key)
      if key.is_a?(Nest)
        @key = key
      else
        @key = Later.key[key]
      end
    end

    def [](event)
      Time.at key[:schedule].zscore(event) rescue nil
    end

    def count
      key[:schedule].zcard
    end

    def set(event, time)
      key[:schedule].zadd time.to_i, event
    end

    def unset(event)
      key[:schedule].zrem event
    end

    def stop
      @stop = true
    end

    def each(&block)
      @stop = false

      loop do
        break if @stop

        time = Time.now.to_i

        key[:schedule].redis.multi
        key[:schedule].zrangebyscore '-inf', time
        key[:schedule].zremrangebyscore '-inf', time
        ids = key[:schedule].redis.exec.first

        key.redis.multi
        ids.each { |id| key[:queue].lpush id }
        key.redis.exec

        event = key[:queue].brpoplpush(key[:now], 1)

        next unless event

        block.call event
      end
    end
  end

  @schedules = {}

  def self.key
    Nest.new('Later')
  end

  def self.[](schedule)
    if @schedules[schedule.to_sym]
      @schedules[schedule.to_sym]
    else
      @schedules[schedule.to_sym] = Schedule.new schedule
    end
  end
end
