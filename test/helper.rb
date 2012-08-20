require 'bundler/setup'
require 'later'
require 'minitest/autorun'

class MiniTest::Unit::TestCase
  def setup
    system 'redis-server', File.join(File.dirname(__FILE__), 'redis.conf')
    until File.exist? 'redis.pid'
      sleep 1
    end
  end

  def teardown
    system "kill `cat redis.pid`"
    sleep 1
  end
end
