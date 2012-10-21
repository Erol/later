require_relative '../helper.rb'

describe Later::Schedule do
  let(:redis) { Redis.new db: 15 }
  let(:key) { Nest.new 'Events', redis }
  let(:schedule) { Later::Schedule.new key }

  before do
    redis.flushdb
  end

  describe '#set' do
    it 'sets a unique event schedule' do
      time = Time.now

      schedule.set 'event', time

      assert_equal 1, schedule.count
      assert_in_delta time, schedule['event'], 0.1
    end
  end

  describe '#unset' do
    it 'unsets a unique event schedule' do
      time = Time.now

      schedule.set 'event', time
      schedule.unset 'event'

      assert_equal 0, schedule.count
      assert_equal nil, schedule['event']
    end
  end

  describe '#count' do
    it 'counts the number of unique event schedules' do
      time = Time.now

      1.upto(3) do |i|
        schedule.set i.to_s, time
        assert_equal i, schedule.count
      end

      1.upto(3) do |i|
        schedule.unset i.to_s
        assert_equal 3 - i, schedule.count
      end
    end
  end

  describe '#each' do
    it 'logs exceptions raised within the block' do
      0.upto(2) do |i|
        schedule.set i, Time.now
      end

      Thread.new do
        sleep 3
        schedule.stop!
      end

      schedule.each do |event|
        raise Exception, "an unknown error for #{event} has occurred"
      end

      exceptions = schedule.exceptions.lrange(0, -1).map{ |e| JSON(e) }

      0.upto(2) do |i|
        assert_equal i.to_s, exceptions[i]['event']
        assert_equal "#<Exception: an unknown error for #{i} has occurred>", exceptions[i]['message']
      end
    end
  end
end
