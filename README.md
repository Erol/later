# Later

[**Later**](erol.github.com/later) is a lightweight Redis-backed event scheduling library for Ruby.

## Usage

Later allows you to set unique events on a schedule and run them in the future:

    require 'later'

    Later[:reservations].set 'event-1', Time.now + 60
    Later[:reservations].set 'event-2', Time.now + 120
    Later[:reservations].set 'event-3', Time.now + 180

Rescheduling an event is simple:

    Later[:reservations].set 'event-1', Time.now + 240

And an event can also be unset:

    Later[key].unset 'event-1'

You can manage multiple schedules using different keys:

    Later[:reservations]
    Later[:appointments]

The schedules are stored on the default Redis instance. If you need a schedule which must reside on a different Redis instance, you can pass a [Nest](github.com/soveran/nest) object when referencing a schedule set.

    redis = Redis.new host: host, port: port
    key = Nest.new :reservations, redis

    Later[key]

### Workers

Workers are Ruby processes that run forever. They allow you to process event schedules in the background:

    require 'later'

    Later[:reservations].each do |event|
      # Do something with the event.
    end

    # This line is never reached.

If for some reason, a worker has to stop itself from running:

    Later[:reservations].each do |event|
      # Do something with the event.

      Later[:reservations].stop! if stop?
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
