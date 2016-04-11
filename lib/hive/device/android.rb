require 'hive/device'

module Hive
  class Device
    class Android < Device
      attr_accessor :model, :brand, :os_version

      def initialize(config)
        @identity = config['id']
        @queue_prefix = config['queue_prefix'].to_s == '' ? '' : "#{config['queue_prefix']}-"
        @model = config['model'].downcase.gsub(/\s/, '_')
        @brand = config['brand'].downcase.gsub(/\s/, '_')
        @os_version = config['os_version']
        super
      end
    end
  end
end
