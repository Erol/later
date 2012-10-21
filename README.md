# Later

[**Later**](erol.github.com/later) is a lean Redis-backed event scheduling library for Ruby.

## Usage

Later allows you to set unique events on a schedule and run them in the future:

    require 'later'

    schedule = Later[:schedule]
    schedule.set 'event-1', Time.now + 60
    schedule.set 'event-2', Time.now + 120
    schedule.set 'event-3', Time.now + 180

Rescheduling an event is simple:

    schedule.set 'event-1', Time.now + 240

And an event can unset with equal ease:

    schedule.unset 'event-1'

You can manage multiple schedules using different keys:

    reservations = Later[:reservations]
    appointments = Later[:appointments]

The schedules are stored on the default Redis instance. If you need a schedule which must reside on a different Redis instance, you can pass a [Nest](github.com/soveran/nest) object when referencing a schedule set.

    redis = Redis.new host: host, port: port
    key = Nest.new 'Reservations', redis

    reservations = Later[key]

### Workers

Workers are Ruby processes that run forever. They allow you to process event schedules in the background:

    require 'later'

    Later[:schedule].each do |event|
      # Do something with the event.
    end

    # This line is never reached.

#### Timeouts, Blocking & Polling

`Later::Schedule#each` accepts an optional `timeout` parameter, which has a default value of `1`. Passing an `Integer` will use Redis' blocking mechanism
to process the schedule and is therefore more efficient. Passing a `Float` will poll Redis using the given timeout, and should
only be used for events which need to be triggered with millisecond precision.

See [BLPOP](http://redis.io/commands/blpop) and [BRPOPLPUSH](http://redis.io/commands/brpoplpush) for more information.

The below schedule will be polled every 0.1 seconds:

    Later[:schedule].each(0.1) do |event|
      # Do something with the event.
    end

#### Stopping

If for some reason, a worker has to stop itself from running:

    Later[:schedule].each do |event|
      # Do something with the event.

      Later[:schedule].stop! if stop?
    end

    # This line is reached when stop? is true and Later[:reservations].stop! is called.

## Installation

Add this line to your application's Gemfile:

    gem 'later'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install later

## Contributing

1. Fork it
2. Create your feature branch ( `git checkout -b my-new-feature` )
3. Create tests and make them pass ( `rake test` )
4. Commit your changes ( `git commit -am 'Added some feature'` )
5. Push to the branch ( `git push origin my-new-feature` )
6. Create a new Pull Request
