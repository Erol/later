require_relative '../helper.rb'

describe Later do
  let(:redis) { Redis.new db: 15 }
  let(:key) { Nest.new 'Events', redis }

  describe '.[]' do
    it 'returns a schedule with the given key' do
      schedule = Later[key]

      assert_instance_of Later::Schedule, schedule
      assert_equal key, schedule.key
    end
  end
end
