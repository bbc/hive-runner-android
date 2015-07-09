
require 'hive/controller/android'
require 'pry'

describe '.detect' do
  it 'Should still work when DeviceDB is unavailable' do
    a = Hive::Controller::Android
    binding.pry
  end
end