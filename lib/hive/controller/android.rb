require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      # 6 hours = 6*60*60 seconds
      TIME_BEFORE_REBOOT = 21600

      def detect
        Hive.devicedb('Hive').poll(Hive.id)
        devices = DeviceAPI::Android.devices

        if devices.empty?
          Hive.logger.debug('No devices attached')
          puts 'No devices attached'
        end

        hive_details = Hive.devicedb('Hive').find(Hive.id)

        hive_details['devices'].each do |device|
          registered_device = devices.select { |a| a.serial == device['serial'] }
          if registered_device.empty?
            # A previously registered device isn't attached
            puts "Removing previously registered device - #{device}"
            Hive.devicedb('Device').hive_disconnect(device['id'])
          else
            # A previously registered device is attached, poll it
            puts "Polling attached device - #{device}"
            Hive.devicedb('Device').poll(device['id'])
            if DeviceAPI::Android::ADB.get_uptime(device['serial']) > (@config['time_before_reboot'] || TIME_BEFORE_REBOOT)
              DeviceAPI::Android::ADB.reboot(device['serial'])
            end
            devices = devices - registered_device
          end
        end

        devices.each do |device|
          begin
            puts "Adding new Android device: #{device.model}"
            Hive.logger.debug("Adding new Android device: #{device.model}")

            attributes = {
                os: 'android',
                os_version: device.version,
                serial: device.serial,
                device_type: 'mobile',
                device_model: device.model,
                device_brand: device.manufacturer,
                device_range: device.range,
                hive: Hive.id
            }

          rescue DeviceAPI::Android::ADBCommandError
            # If a device has been disconnected while we're trying to add it, the device_api
            # gem will throw an error
            Hive.logger.debug('Device disconnected while attempting to add')
          end
          registration = Hive.devicedb('Device').register(attributes)
          Hive.devicedb('Device').hive_connect(registration['id'], Hive.id)
        end

        rows = []

        hive_details = Hive.devicedb('Hive').find(Hive.id)
        unless hive_details['devices'].empty?
          rows = hive_details['devices'].map do |device|
            [
                "#{device['device_brand']} #{device['device_model']}",
                device['serial'],
                (device['device_queues'].map { |queue| queue['name']}).join("\n"),
                device['status']
            ]
          end
        end
        table = Terminal::Table.new :headings => ['Device', 'Serial', 'Queue Name', 'Status'], :rows => rows

        puts table

        if hive_details.key?('devices')
          hive_details['devices'].collect do |device|
            #Hive.create_object(@device_class).new(@config.merge(device))
            Object.const_get(@device_class).new(@config.merge(device))
          end
        else
          []
        end
      end
    end
  end
end
