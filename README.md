# Later

[**Later**](erol.github.com/later) is a Redis-backed event scheduling library for Ruby.

## Usage

Later allows you to manage schedule sets:

    require 'later'

    Later[:reservations]
    Later[:appointments]

The schedule sets are referenced based on the default Redis instance. If you need a schedule set which resides on a different Redis instance, you can pass a [Nest](github.com/soveran/nest) object when referencing a schedule set.

    redis = Redis.new host: host, port: port
    key = Nest.new :reservations, redis

    Later[key]

Setting an event schedule is simple:

    Later[key].set 'my-unique-event', Time.now + 60
	
And can be reschedule with equal simplicity:

    Later[key].set 'my-unique-event', Time.now + 120

An event schedule can also be unset:

    Later[key].unset 'my-unique-event'
	
Note that event names should be unique in the scope of its schedule set.
	
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

      Later[:reservations].stop if stop?
    end

    # This line is reached if stop? is true.

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
