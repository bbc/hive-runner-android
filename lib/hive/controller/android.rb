require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      def detect
        self.detect_hive_mind
      end

      # Register with Hive Mind (New)
      def detect_hive_mind
        devices = DeviceAPI::Android.devices
        Hive.logger.debug('HM) No devices attached') if devices.empty?

        if not Hive.hive_mind.device_details.has_key? :error
          # Selecting only android mobiles
          connected_devices = Hive.hive_mind.device_details['connected_devices'].select{ |d| d['device_type'] == 'Mobile' && d['operating_system_name'] == 'android' }

          to_poll = []
          attached_devices = []
          connected_devices.each do |device|
            Hive.logger.debug("HM) Device details: #{device.inspect}")
            registered_device = devices.select { |a| a.serial == device['serial'] && a.status != :unauthorized && a.status != :no_permissions}
            if registered_device.empty?
              # A previously registered device isn't attached
              Hive.logger.debug("HM) A previously registered device has disappeared: #{device}")
            else
              # A previously registered device is attached, poll it
              Hive.logger.debug("HM) Setting #{device} to be polled")
              Hive.logger.info("HM) Stuff: #{registered_device.inspect}")
              begin
                attached_devices << self.create_device(device.merge('os_version' => registered_device[0].version))
                to_poll << device['id']
              rescue DeviceAPI::DeviceNotFound => e
                Hive.logger.warn("HM) Device disconnected before registration (serial: #{device['serial']})")
              rescue => e
                Hive.logger.warn("HM) Error with connected device: #{e.message}")
              end

              devices = devices - registered_device
            end
          end

          # Poll already registered devices
          Hive.logger.debug("HM) Polling: #{to_poll}")
          Hive.hive_mind.poll(*to_poll)

          # Register new devices
          devices.select{|a| a.status != :unauthorized && a.status != :no_permissions}.each do |device|
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
              Hive.logger.info("HM) Device registered: #{dev}")
            rescue DeviceAPI::DeviceNotFound => e
              Hive.logger.warn("HM) Device disconnected before registration (serial: #{device.serial})")
            rescue => e
              Hive.logger.warn("HM) Error with connected device: #{e.message}")
            end
          end

        else
          Hive.logger.info('HM) No Hive Mind connection')
          Hive.logger.debug("HM) Error: #{Hive.hive_mind.device_details[:error]}")
          # Hive Mind isn't available, use DeviceAPI instead
          device_info = devices.select { |a| a.status != :unauthorized && a.status != :no_permissions }.map do |device|
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
