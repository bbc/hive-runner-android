require 'hive/device'

module Hive
  class Device
    class Android < Device
      attr_accessor :model, :brand, :os_version

      def initialize(config)
        @identity = config['id']
        @queue_prefix = 'testing'
        @model = config['model'].downcase.gsub(/\s/, '_')
        @brand = config['brand'].downcase.gsub(/\s/, '_')
        @os_version = config['os_version']

        Hive.logger.info("Config: #{config.inspect}")
        #config['queues'] = calculate_queue_names
        #config['queues'] = [] if not config.has_key? 'queues'
        #config['queues'] = calculate_queue_names + config['queues']
        config['queues'] = calculate_queue_names + (config.has_key?('queues') ? config['queues'] : [])

        super
      end

      # Uses either DeviceAPI or DeviceDB to generate queue names for a device
      def calculate_queue_names
        [
          self.model,
          self.brand,
          'android',
          "android-#{self.os_version}",
          "android-#{self.os_version}-#{self.model}"
        ]
      end
    end
  end
end
