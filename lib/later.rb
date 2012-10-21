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

    # Get the Nest key of the schedule.
    #
    #   Later[:reservations].key #=> Later::reservations

    def key
      @key
    end

    # Get the Nest key of the schedule exception list.
    #
    #   Later[:reservations].exceptions #=> Later::reservations::exceptions

    def exceptions
      @exceptions ||= key[:exceptions]
    end

    # Get the schedule time of a unique event.
    #
    #   Later[:reservations].set 'event-1', Time.parse('2012-09-28 11:36:17 +0800')
    #   Later[:reservations]['event-1'] #=> 2012-09-28 11:36:17 +0800

    def [](event)
      Time.at key[:schedule].zscore(event) rescue nil
    end

    # Gets the number of unique scheduled events.
    #
    #   Later[:reservations].set 'event-1', Time.now + 60
    #   Later[:reservations].set 'event-2', Time.now + 120
    #   Later[:reservations].set 'event-3', Time.now + 180
    #   Later[:reservations].count #=> 3

    def count
      key[:schedule].zcard
    end

    # Set a unique event to the schedule.
    #
    #   Later[:reservations].set 'event-1', Time.now + 60

    def set(event, time)
      key[:schedule].zadd time.to_i, event
    end

    # Unset a unique event from the schedule.
    #
    #   Later[:reservations].unset 'event-2'

    def unset(event)
      key[:schedule].zrem event
    end

    # When called inside an `each` block, `stop!` signals the block to halt processing of the schedule.
    #
    #   Later[:reservations].each do |event|
    #     Later[:reservations].stop!
    #   end

    def stop!
      @stop = true
    end

    # Process each event on the schedule. The block only gets called when an event is due to run based on the current time.
    #
    #   Later[:reservations].each do |event|
    #     # Do something with the event
    #   end

    def each(&block)
      @stop = false

      loop do
        break if stop?

        time = Time.now.to_i

        push_to_queue pop_from_schedules(time)

        event = pop_from_queue

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

    def pop_from_queue
      queue.brpoplpush(backup, 1)
    end
  end

  @schedules = {}

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
