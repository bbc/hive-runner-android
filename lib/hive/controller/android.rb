require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      def initialize
        @device_type ||= 'Mobile'
        super
      end

      # Register and poll connected devices
      def detect
        if Hive.hive_mind.device_details.has_key? :error
          detect_without_hivemind
        else
          detect_with_hivemind
        end
      end

      def detect_with_hivemind
        connected_devices = get_connected_devices
        Hive.logger.debug('No devices attached') if connected_devices.empty?

        # Selecting only android mobiles
        hivemind_devices = get_hivemind_devices

        to_poll = []
        attached_devices = []
        hivemind_devices.each do |device|
          Hive.logger.debug("Device details: #{device.inspect}")
          registered_device = connected_devices.select { |a| a.serial == device['serial'] }
          if registered_device.empty?
            # A previously registered device isn't attached
            Hive.logger.debug("A previously registered device has disappeared: #{device}")
          else
            # A previously registered device is attached, poll it
            Hive.logger.debug("Setting #{device} to be polled")
            Hive.logger.debug("Device: #{registered_device.inspect}")
            begin
              attached_devices << self.create_device(device.merge('os_version' => registered_device[0].version))
              to_poll << device['id']
            rescue DeviceAPI::DeviceNotFound => e
              Hive.logger.warn("Device disconnected before registration (serial: #{device['serial']})")
            rescue => e
              Hive.logger.warn("Error with connected device: #{e.message}")
            end

            connected_devices = connected_devices - registered_device
          end
        end

        # Poll already registered devices
        Hive.logger.debug("Polling: #{to_poll}")
        Hive.hive_mind.poll(*to_poll)

        # Register new devices
        connected_devices.select{|a| a.status != :unauthorized && a.status != :no_permissions}.each do |device|
          begin
            dev = Hive.hive_mind.register(
                hostname: device.model,
                serial: device.serial,
                macs: [device.wifi_mac_address],
                ips: [device.ip_address],
                brand: device.manufacturer.capitalize,
                model: device.model,
                device_type: 'Mobile',
                imei: device.imei,
                operating_system_name: 'android',
                operating_system_version: device.version
            )
            Hive.hive_mind.connect(dev['id'])
            Hive.logger.info("Device registered: #{dev}")
          rescue DeviceAPI::DeviceNotFound => e
            Hive.logger.warn("Device disconnected before registration (serial: #{device.serial})")
          rescue => e
            Hive.logger.warn("Error with connected device: #{e.message}")
          end
        end

        Hive.logger.info(attached_devices)
        attached_devices
      end

      def detect_without_hivemind
        connected_devices = get_connected_devices
        Hive.logger.debug('No devices attached') if connected_devices.empty?

        Hive.logger.info('No Hive Mind connection')
        Hive.logger.debug("Error: #{Hive.hive_mind.device_details[:error]}")
        # Hive Mind isn't available, use DeviceAPI instead
        device_info = connected_devices..map do |device|
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

        Hive.logger.info(attached_devices)
        attached_devices
      end

      def get_connected_devices
        DeviceAPI::Android.devices.select do |s|
          a.status != :unauthorized &&
          a.status != :no_permissions
        end
      end

      def get_hivemind_devices
        begin
          Hive.hive_mind.device_details['connected_devices'].select{ |d| d['device_type'] == @device_type && d['operating_system_name'] == 'android' }
        rescue NoMethodError
          # Failed to find connected devices
          raise Hive::Controller::DeviceDetectionFailed
        end
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
