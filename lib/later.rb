require 'later/version'
require 'redis'
require 'nest'
require 'json'

module Later
  class Schedule
    def initialize(key)
      if key.is_a?(Nest)
        @key = key
      else
        @key = Later.key[key]
      end
    end

    def key
      @key
    end

    def exceptions
      @exceptions ||= key[:exceptions]
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

        schedule.redis.multi
        schedule.zrangebyscore '-inf', time
        schedule.zremrangebyscore '-inf', time
        ids = schedule.redis.exec.first

        key.redis.multi do
          ids.each { |id| queue.lpush id }
        end

        event = queue.brpoplpush(backup, 1)

        next unless event

        begin
          block.call event
        rescue Exception => e
          exceptions.rpush JSON(time: Time.now, event: event, message: e.inspect)
        ensure
          backup.del
        end
      end
    end

    protected

    def schedule
      @schedule ||= key[:schedule]
    end

    def queue
      @queue ||= key[:queue]
    end

    def backup
      @backup ||= queue[Socket.gethostname][Process.pid]
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
