require 'webmock/rspec'

$LOAD_PATH << File.expand_path('../../lib', __FILE__)

ENV['HIVE_CONFIG'] = File.expand_path('../', __FILE__)

RSpec.configure do |config|
  config.before(:each) do
    # Mocks for Hive Mind
    body = <<BODY
{
  "connected_devices": [
    {
      "device_type": "Mobile",
      "operating_system_name": "android"
    },
    {
      "device_type": "Tv",
      "operating_system_name": "android"
    },
    {
      "device_type": "Mobile",
      "operating_system_name": "ios"
    },
    {
      "device_type": "Mobile",
      "operating_system_name": "android"
    },
    {
      "device_type": "Mobile",
      "operating_system_name": "android"
    },
    {
      "device_type": "Tv"
    },
    {
      "device_type": "Mobile",
      "operating_system_name": "android"
    },
    {
      "device_type": "Mobile",
      "operating_system_name": "android"
    }
  ]
}
BODY
    stub_request(:post, "http://hivemind/api/devices/register.json").
         to_return(:status => 200, :body => body, :headers => {})
    
    stub_request(:post, "http://hivemind/api/device_statistics/upload.json").
         to_return(:status => 200, :body => "", :headers => {})
  end
end
