require 'spec_helper'
require 'hive/controller/android'

RSpec.describe Hive::Controller::Android do
  let(:cont) { Hive::Controller::Android.new }

  describe '#get_hivemind_devices' do
    it 'selects only Mobile devices' do
      cont.get_hivemind_devices.each do |cd|
        expect(cd['device_type']).to eq 'Mobile'
      end
    end

    it 'selects only Android devices' do
      cont.get_hivemind_devices.each do |cd|
        expect(cd['operating_system_name']).to eq 'android'
      end
    end

    # Set 5 Android Mobile devices in the mock data
    it 'finds 5 devices' do
      expect(cont.get_hivemind_devices.count).to eq 5
    end
  end
end
