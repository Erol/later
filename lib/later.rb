require 'later/version'
require 'redis'
require 'nest'
require 'json'
require 'predicates'

module Later
  class Schedule
    extend Predicates

    predicate :stop?

    def initialize(key)
      if key.is_a?(Nest)
        @key = key
      else
        @key = Later.key[key]
      end
    end

    # Returns the Nest key of this schedule.
    #
    #   Later[:reservations].key #=> Later:reservations
    #
    def key
      @key
    end

    # Returns the Nest key of this schedule's exception list.
    #
    #   Later[:reservations].exceptions #=> Later:reservations:exceptions
    #
    def exceptions
      @exceptions ||= key[:exceptions]
    end

    # Returns the time of a scheduled unique event.
    #
    #   Later[:reservations].set 'event-1', Time.parse('2012-09-28 11:36:17 +0800')
    #   Later[:reservations]['event-1'] #=> 2012-09-28 11:36:17 +0800
    #
    def [](event)
      Time.at key[:schedule].zscore(event) rescue nil
    end

    # Returns the number of scheduled unique events.
    #
    #   Later[:reservations].set 'event-1', Time.now + 60
    #   Later[:reservations].set 'event-2', Time.now + 120
    #   Later[:reservations].set 'event-3', Time.now + 180
    #   Later[:reservations].count #=> 3
    #
    def count
      key[:schedule].zcard
    end

    # Returns `true` if there are no scheduled unique events. Returns `false` otherwise.
    #   Later[:reservations].set 'event-1', Time.now + 60
    #   Later[:reservations].empty? #=> false
    #   Later[:reservations].unset 'event-1'
    #   Later[:reservations].empty? #=> true
    #
    def empty?
      count.zero?
    end

    # Sets a unique event to this schedule.
    #
    #   Later[:reservations].set 'event-1', Time.now + 60
    #
    def set(event, time)
      key[:schedule].zadd time.to_f, event
    end

    # Unsets a unique event from this schedule.
    #
    #   Later[:reservations].unset 'event-1'
    #
    def unset(event)
      key[:schedule].zrem event
    end

    # When called inside an `each` block, `stop!` signals the block to halt processing of this schedule.
    #
    #   Later[:reservations].each do |event|
    #     Later[:reservations].stop!
    #   end
    #
    def stop!
      @stop = true
    end

    # Processes each scheduled unique event. The block only gets called when an event is due to run based on the current time.
    #
    # Accepts an optional `timeout` parameter with a default value of `1`. Passing an `Integer` will use Redis' blocking mechanism
    # to process the schedule and is therefore more efficient. Passing a `Float` will poll Redis using the given timeout, and should
    # only be used for events which need to be triggered with millisecond precision.
    #
    #   Later[:reservations].each do |event|
    #     # Do something with the event
    #   end
    #
    # The schedule will be polled every 0.1 seconds:
    #
    #   Later[:reservations].each(0.1) do |event|
    #     # Do something with the event
    #   end
    #
    def each(timeout = 1, &block)
      @stop = false

      loop do
        break if stop?

        time = Time.now.to_f

        push_to_queue pop_from_schedules(time)
        next unless event = pop_from_queue(timeout)

        begin
          block.call event
        rescue Exception => e
          exceptions.rpush JSON(time: Time.now, event: event, message: e.inspect)
        ensure
          local.del
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

    def local
      @local ||= queue[Socket.gethostname][Process.pid]
    end

    def pop_from_schedules(time)
      schedule.redis.multi do
        schedule.zrangebyscore '-inf', time
        schedule.zremrangebyscore '-inf', time
      end.first
    end

    def push_to_queue(ids)
      key.redis.multi do
        ids.each { |id| queue.lpush id }
      end
    end

    def pop_from_queue(timeout)
      if timeout.is_a? Integer
        queue.brpoplpush(local, timeout)
      else
        result = queue.rpoplpush(local)
        sleep timeout unless result
        result
      end
    end
  end

  @schedules = {}

  # Returns the Nest key of this module.
  #
  #   Later[:reservations].key #=> Later::reservations
  #
  def self.key
    Nest.new('Later')
  end

  # The easiest way to create or reference a schedule. Returns an instance of a Later::Schedule with the given key.
  #
  #   Later[:reservations] #=> #<Later::Schedule:0x007faf3b054f50 @key="Later:reservations">
  #
  def self.[](schedule)
    @schedules[schedule.to_sym] ||= Schedule.new schedule
  end
end
