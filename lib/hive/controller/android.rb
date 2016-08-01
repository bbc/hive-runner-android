require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller
      attr_accessor :devices
      attr_accessor :attached_devices

      def detect(device_type = 'Mobile')
        # device_type should be either 'Mobile' or 'Tv'
        @device_type = device_type
        connected_devices = get_connected_devices # get all connected devices
        to_poll = select_devices(connected_devices) # select devices to poll
        poll_devices(to_poll) # poll devices
        register_new_devices
        @attached_devices
      end

      def get_connected_devices
        # get a list of connected devices from Hivemind or DeviceAPI
        @devices = DeviceAPI::Android.devices
        Hive.logger.debug('No devices attached') if devices.empty?

        unless Hive.hive_mind.device_details.has_key?(:error)
          # Selecting only android mobiles
          begin
            connected_devices = Hive.hive_mind.device_details['connected_devices'].select{ |d| d['device_type'] == @device_type && d['operating_system_name'] == 'android' }
          rescue NoMethodError
            # Failed to find connected devices
            raise Hive::Controller::DeviceDetectionFailed
          end
        else
          Hive.logger.info('No Hive Mind connection')
          Hive.logger.debug("Error: #{Hive.hive_mind.device_details[:error]}")
          # Hive Mind isn't available, use DeviceAPI instead
          device_info = @devices.select do |a|
              a.status != :unauthorized &&
              a.status != :no_permissions
            end.map do |device|
            {
             'id' => device.serial,
             'serial' => device.serial,
             'status' => 'idle',
             'model' => device.model,
             'brand' => device.manufacturer,
             'os_version' => device.version
            }
          end

          # attached_devices is either fully set here (if there is no Hivemind connection) 
          # or in select_devices (if there is a Hivemind connection), not both
          @attached_devices = device_info.collect do |physical_device|
            self.create_device(physical_device)
          end
        end

        connected_devices
      end

      def select_devices(connected_devices)
        # select devices that we want to poll
        to_poll = []
        @attached_devices || []
        connected_devices.each do |device|
          registered_device = @devices.select do |a|
            a.serial == device['serial'] &&
                a.status != :unauthorized &&
                a.status != :no_permissions
          end

          if registered_device.empty? # A previously registered device isn't attached
            Hive.logger.debug("A previously registered device has disappeared: #{device}")
          else # A previously registered device is attached, poll it
            Hive.logger.debug("Setting #{device} to be polled")
            Hive.logger.debug("Device: #{registered_device.inspect}")

            begin
              @attached_devices << self.create_device(device.merge('os_version' => registered_device[0].version))
              to_poll << device['id']

            rescue DeviceAPI::DeviceNotFound => e
              Hive.logger.warn("Device disconnected before registration (serial: #{device['serial']})")
            rescue => e
              Hive.logger.warn("Error with connected device: #{e.message}")
            end

            @devices = @devices - registered_device
          end
        end

        to_poll
      end


      def poll_devices(to_poll)
        # poll selected devices

        Hive.logger.debug("Polling: #{to_poll}")
        Hive.hive_mind.poll(*to_poll)
      end

      def register_new_devices
        # Register new devices with Hivemind
        @devices.select { |a| a.status != :unauthorized && a.status != :no_permissions }.each do |device|
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
      end

      def display_devices(hive_details)
        rows = []
        if hive_details.key?('devices')
          unless hive_details['devices'].empty?
            rows = hive_details['devices'].map do |device|
              [
                  "#{device['device_brand']} #{device['device_model']}",
                  device['serial'],
                  (device['device_queues'].map { |queue| queue['name'] }).join("\n"),
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
