require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'
require 'pry'

module Hive
  class Controller
    class Android < Controller
      def detect
        Hive.devicedb('Hive').poll(Hive.id)

        devices = DeviceAPI::Android.devices

        if devices.empty?
          # No devices have been detected, log and return
          Hive.logger.debug('No devices attached')
          puts 'No devices attached'
          return []
        end
        # Register the attached devices
        registered_devices = []
        devices.each do |device|
          begin
          Hive.logger.debug("Found Android device: #{device.model}")
          puts "Android device #{device.model} found - adding to Hive"

          attributes = {
              os: 'android',
              os_version: device.version,
              serial: device.serial,
              device_type: 'mobile',
              device_model: device.model,
              device_brand: device.manufacturer,
              hive: Hive.id
          }
          rescue DeviceAPI::Android::ADBCommandError
            # If a device has been disconnected while we're trying to add it, the device_api
            # gem will throw an error
            Hive.logger.debug('Device disconnected while attempting to add')
          end
          registration = Hive.devicedb('Device').register(attributes)
          registered_devices << Hive.devicedb('Device').hive_connect(registration['id'], Hive.id)
        end

        hive_details = Hive.devicedb('Hive').find(Hive.id)

        if hive_details.key?('devices')
          # See what has been previously attached and remove those if they're not currently attached
          (hive_details['devices'] - registered_devices).each do |device|
            Hive.devicedb('Device').hive_disconnect(device['id'])
          end
        end

        hive_details = Hive.devicedb('Hive').find(Hive.id)
        if hive_details.key?('devices')
          hive_details['devices'].collect do |device|
            Hive.logger.debug("Found Android device #{device}")
            device['queues'] = device['device_queues'].collect do |queue_details|
              puts "Queue: #{queue_details['name']}"
              queue_details['name']
            end
            Object.const_get(@device_class).new(@config.merge(device))
          end
        else
          []
        end
      end
    end
  end
end
