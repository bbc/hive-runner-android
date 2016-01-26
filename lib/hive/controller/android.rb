require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      def detect
        devices = DeviceAPI::Android.devices
        Hive.logger.debug('No devices attached') if devices.empty?

        if not Hive.hive_mind.device_details.has_key? :error
          # Checking device_type for 'Mobile'
          # TODO Check for os to ensure Android
          connected_devices = Hive.hive_mind.device_details['connected_devices'].select{ |d| d['device_type'] == 'Mobile' }

          to_poll = []
          attached_devices = []
          connected_devices.each do |device|
  Hive.logger.info("Device details: #{device.inspect}")
            registered_device = devices.select { |a| a.serial == device['serial'] && a.status != :unauthorized }
            if registered_device.empty?
              # A previously registered device isn't attached
              Hive.logger.debug("Removing previously registered device - #{device}")
              Hive.hive_mind.disconnect(device['id'])
            else
              # A previously registered device is attached, poll it
              Hive.logger.debug("Setting #{device} to be polled")
              Hive.logger.info("Stuff: #{registered_device.inspect}")
              attached_devices << self.create_device(device.merge('os_version' => registered_device[0].version))
              to_poll << device['id']

              devices = devices - registered_device
            end
          end

          # Poll already registered devices
          Hive.logger.debug("Polling: #{to_poll}")
          Hive.hive_mind.poll(*to_poll)

          # Register new devices
          devices.select{|a| a.status != :unauthorized}.each do |device|
            dev = Hive.hive_mind.register(
                hostname: device.model,
                serial: device.serial,
                macs: [device.wifi_mac_address],
                ips: [device.ip_address],
                brand: device.manufacturer.capitalize,
                model: device.model,
                device_type: 'Mobile',
                imei: device.imei,
                hive_id: Hive.id
            )
            Hive.hive_mind.connect(dev['id'])
            Hive.logger.info("Device registered: #{dev}")
          end

        else
          Hive.logger.info('No Hive Mind connection')
          # Hive Mind isn't available, use DeviceAPI instead
          device_info = devices.select { |a| a.status != :unauthorized }.map do |device |
            {
              'id' =>  device.serial,
              'serial' => device.serial,
              'status' => 'idle',
              'model' => device.model,
              'brand' => device.manufacturer,
              'os_version' => device.version
            }
          end

          attached_devices = device_info.collect do |physical_device|
            self.create_device(physical_device)
          end
        end

        Hive.logger.info(attached_devices)
        attached_devices
      end

      def display_devices(hive_details)
        rows = []
        if hive_details.key?('devices')
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
        end
        table = Terminal::Table.new :headings => ['Device', 'Serial', 'Queue Name', 'Status'], :rows => rows

        Hive.logger.info(table)
      end
    end
  end
end
