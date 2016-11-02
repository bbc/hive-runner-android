require 'spec_helper'
require 'hive/controller/android'


RSpec.describe Hive::Controller::Android do
  let(:controller) { Hive::Controller::Android.new({}) }

  describe '#detect' do
    context 'with Hive Mind' do
      before(:each) do
        reset_hive config: 'config_with_hivemind'
      end

      it 'detects 3 devices when 5 are defined in Hive Mind and 3 are attached' do
        # Mock devices
        hm_list = []
        adb_list = []

        # Android mobiles recorded in Hive Mind and attached
        (1..3).each do |i|
          hm_list << hm_device(id: i)
          adb_list << adb_device(id: i)
        end

        # Android mobiles not recorded in Hive Mind but attached
        (4..5).each do |i|
          hm_list << hm_device(id: i)
        end

        mock_devices id: 99, hm_devices: hm_list, adb_devices: adb_list

        expect(controller.detect.count).to eq 3
      end

      context '3 devices in Hive mind and these 3 plus 2 more attached' do
        before(:each) do
          # Mock devices
          hm_list = []
          adb_list = []

          # Android mobiles recorded in Hive Mind and attached
          (1..3).each do |i|
            hm_list << hm_device(id: i)
            adb_list << adb_device(id: i)
          end

          # Android mobiles not recorded in Hive Mind but attached
          (4..5).each do |i|
            adb_list << adb_device(id: i)
          end

          mock_devices id: 98, hm_devices: hm_list, adb_devices: adb_list
          # Register new devices
          stub_request(:post, "http://hivemind/api/devices/register.json").
            with(:body => /device%5Bserial%5D=serial4/).
            to_return(:status => 200, :body => {id: 4}.to_json, :headers => {})
          stub_request(:post, "http://hivemind/api/devices/register.json").
            with(:body => /device%5Bserial%5D=serial5/).
            to_return(:status => 200, :body => {id: 5}.to_json, :headers => {})
        end

        it 'detects 3' do
          expect(controller.detect.count).to eq 3
        end

        it 'registeres the first extra device' do
          expect(controller.detect).to have_requested(:post, "http://hivemind/api/devices/register.json").
            with(:body => /device%5Bserial%5D=serial4/)
        end

        it 'registeres the second extra device' do
          expect(controller.detect).to have_requested(:post, "http://hivemind/api/devices/register.json").
            with(:body => /device%5Bserial%5D=serial5/)
        end

        it 'connects the first device to the hive' do
          expect(controller.detect).to have_requested(:put, "http://hivemind/api/plugin/hive/connect.json").
            with(:body => "connection%5Bdevice_id%5D=4&connection%5Bhive_id%5D=98")
        end

        it 'connects the first device to the hive' do
          expect(controller.detect).to have_requested(:put, "http://hivemind/api/plugin/hive/connect.json").
            with(:body => "connection%5Bdevice_id%5D=5&connection%5Bhive_id%5D=98")
        end
      end

      it 'detects 6 attached devices when Hive Mind registration fails' do
        # Mock devices
        hm_list = []
        adb_list = []

        # Android mobiles recorded in Hive Mind and attached
        (1..2).each do |i|
          hm_list << hm_device(id: i)
          adb_list << adb_device(id: i)
        end

        # Android mobiles recorded in Hive Mind but not attached
        (3..5).each do |i|
          hm_list << hm_device(id: i)
        end

        # Android mobiles not recorded in Hive Mind but attached
        (6..9).each do |i|
          adb_list << adb_device(id: i)
        end

        mock_devices id: 97, hm_devices: hm_list, adb_devices: adb_list, register_fail: true

        expect(controller.detect.count).to eq 6
      end

      it 'detects only Android devices' do
        # Mock devices
        hm_list = []
        adb_list = []

        # Android mobiles recorded in Hive Mind and attached
        (1..3).each do |i|
          hm_list << hm_device(id: i)
          adb_list << adb_device(id: i)
        end

        (4..8).each do |i|
          hm_list << hm_device(id: i, os: 'ios')
        end

        mock_devices id: 96, hm_devices: hm_list, adb_devices: adb_list

        expect(controller.detect.count).to eq 3
      end

      it 'detects only mobile devices' do
        # Mock devices
        hm_list = []
        adb_list = []

        # Android mobiles recorded in Hive Mind and attached
        (1..3).each do |i|
          hm_list << hm_device(id: i)
          adb_list << adb_device(id: i)
        end

        (4..8).each do |i|
          hm_list << hm_device(id: i, device_type: 'Tv')
          adb_list << adb_device(id: i, remote: true)
        end

        mock_devices id: 96, hm_devices: hm_list, adb_devices: adb_list

        expect(controller.detect.count).to eq 3
      end
    end
  end

  context 'without Hive Mind' do
    before(:each) do
      reset_hive config: 'config_without_hivemind'
    end

    it 'detects 4 android devices attached' do
      # 4 Android mobiles attached
      adb_list = []
      (1..4).each do |i|
        adb_list << adb_device(id: i)
      end
      mock_devices id: 79, adb_devices: adb_list

      expect(controller.detect.count).to eq 4
    end

    it 'detects only mobile devices' do
      # Mock devices
      hm_list = []
      adb_list = []

      # Android mobiles recorded in Hive Mind and attached
      (1..3).each do |i|
        adb_list << adb_device(id: i)
      end

      (4..8).each do |i|
        adb_list << adb_device(id: i, remote: true)
      end
      mock_devices id: 78, hm_devices: hm_list, adb_devices: adb_list

      expect(controller.detect.count).to eq 3
    end
  end
end
