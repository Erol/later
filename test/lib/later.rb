require_relative '../helper.rb'

class LaterTest < MiniTest::Unit::TestCase
  def setup
    super

    @redis = Redis.new host: '127.0.0.1', port: 6666
    @key = Nest.new 'Events', @redis
  end

  def test_set_a_unique_event_schedule
    time = Time.now

    Later[@key].set '1', time

    assert_equal 1, Later[@key].count
    assert_in_delta time, Later[@key]['1'], 1
  end

  def test_unset_a_unique_event_schedule
    time = Time.now

    Later[@key].set '1', time
    Later[@key].unset '1'

    assert_equal 0, Later[@key].count
    assert_equal nil, Later[@key]['1']
  end

  def test_count_set_and_unset_event_schedules
    time = Time.now

    1.upto(3) do |i|
      Later[@key].set i.to_s, time
      assert_equal i, Later[@key].count
    end

    1.upto(3) do |i|
      Later[@key].unset i.to_s
      assert_equal 3 - i, Later[@key].count
    end
  end

  def test_process_many_event_schedules
    start = Time.now + 2

    times = []
    schedules = Hash.new { |h,k| h[k] = [] }

    1.upto(100) do |i|
      time = start + i / 10
      times.unshift time
      schedules[time].unshift event: i.to_s, time: time
    end

    times.map{ |time| schedules[time] }.flatten.shuffle.each do |schedule|
      Later[@key].set schedule[:event], schedule[:time]
    end

    Thread.new do
      sleep 2 + 10 + (start - Time.now).to_i
      Later[@key].stop
    end

    Later[@key].each do |event|
      time = times.pop

      assert_in_delta time, Time.now, 1.2
      assert_includes schedules[time], {event: event, time: time}
    end

    assert_equal 0, Later[@key].count
  end

  def test_exceptions_raised_within_the_worker_loop_are_handled_and_logged
    start = Time.now + 2

    1.upto(3) do |i|
      Later[@key].set i.to_s, start + i
    end

    Thread.new do
      sleep 2 + 3 + (start - Time.now).to_i
      Later[@key].stop
    end

    Later[@key].each do |event|
      raise Exception, "an unknown error for #{event} has occurred"
    end

    assert_equal 0, Later[@key].count

    exceptions = Later[@key].exceptions.lrange 0, -1
    exceptions = exceptions.map{ |e| JSON(e) }

    assert_equal '1', exceptions[0]['event']
    assert_equal '#<Exception: an unknown error for 1 has occurred>', exceptions[0]['message']
    assert_equal '2', exceptions[1]['event']
    assert_equal '#<Exception: an unknown error for 2 has occurred>', exceptions[1]['message']
    assert_equal '3', exceptions[2]['event']
    assert_equal '#<Exception: an unknown error for 3 has occurred>', exceptions[2]['message']
  end
end
