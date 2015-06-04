require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      # 6 hours = 6*60*60 seconds
      TIME_BEFORE_REBOOT = 21600

      def reboot_if_required(serial)
        if DeviceAPI::Android::ADB.get_uptime(serial) > (@config['time_before_reboot'] || TIME_BEFORE_REBOOT)
          DeviceAPI::Android::ADB.reboot(serial)
        end
      end

      def calculate_queue_names(device)
        queues = [
                    device['device_model'],
                    device['device_brand'],
                    device['os'],
                    "#{device['os']}-#{device['os_version']}",
                    "#{device['os']}-#{device['os_version']}-#{device['device_model']}"
                 ]

        queues << device["features"] unless device["features"].empty?

        queues.flatten
      end

      def calculate_device_name(device)
        "mobile-#{device.manufacturer}-#{device.model}".gsub(' ', '_').downcase
      end

      def populate_queues(device)
        queues = calculate_queue_names(device)

        devicedb_queues = device['device_queues'].map { |d| d['name'] }
        # Check to see if the queues have already been registered with this device
        missing_queues = (queues - devicedb_queues) + (devicedb_queues - queues)
        return if missing_queues.empty?

        queues << missing_queues

        queue_ids = queues.flatten.uniq.map { |queue| find_or_create_queue(queue) }

        values = {
            name: device['name'],
            hive_id: device['hive_id'],
            feature_list: device['features'],
            device_queue_ids: queue_ids
        }

        Hive.devicedb('Device').edit(device['id'], values)
      end

      def find_or_create_queue(name)
        queue = Hive.devicedb('Queue').find_by_name(name)
        return queue.first['id'] unless queue.empty?

        create_queue(name, "#{name} queue created by Hive Runner")['id']
      end

      def create_queue(name, description)
        queue_attributes = {
            name: name,
            description: description
        }

        Hive.devicedb('Queue').register(device_queue: queue_attributes )
      end

      def detect
        Hive.logger.debug("#{Time.now} Polling hive: #{Hive.id}")
        Hive.devicedb('Hive').poll(Hive.id)
        Hive.logger.debug("#{Time.now} Finished polling hive: #{Hive.id}")
        devices = DeviceAPI::Android.devices

        Hive.logger.debug('No devices attached') if devices.empty?
        Hive.logger.debug("#{Time.now} Retrieving hive details")
        hive_details = Hive.devicedb('Hive').find(Hive.id)
        Hive.logger.debug("#{Time.now} Finished fetching hive details")

        unless hive_details.key?('devices')
          Hive.logger.debug('Could not connect to DeviceDB at this time')
          return []
        end

        unless hive_details['devices'].empty?
          hive_details['devices'].select {|a| a['os'] == 'android'}.each do |device|
            registered_device = devices.select { |a| a.serial == device['serial']}
            if registered_device.empty?
              # A previously registered device isn't attached
              Hive.logger.debug("Removing previously registered device - #{device}")
              Hive.devicedb('Device').hive_disconnect(device['id'])
            else
              # A previously registered device is attached, poll it
              Hive.logger.debug("#{Time.now} Polling attached device - #{device}")
              Hive.devicedb('Device').poll(device['id'])
              Hive.logger.debug("#{Time.now} Finished polling device")
              reboot_if_required(device['serial'])

              # Make sure that this device has all the queues it should have
              populate_queues(device)

              devices = devices - registered_device
            end
          end
        end

        devices.each do |device|
          register_new_device(device)
        end

        display_devices

        if hive_details.key?('devices')
          hive_details['devices'].select {|a| a['os'] == 'android'}.collect do |device|
            #Hive.create_object(@device_class).new(@config.merge(device))
            Object.const_get(@device_class).new(@config.merge(device))
          end
        else
          []
        end
      end

      def register_new_device(device)
        begin
          Hive.logger.debug("Adding new Android device: #{device.model}")

          attributes = {
              os: 'android',
              os_version: device.version,
              serial: device.serial,
              device_type: 'mobile',
              device_model: device.model,
              device_brand: device.manufacturer,
              device_range: device.range,
              name: calculate_device_name(device),
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

      def display_devices
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
      end
    end
  end
end
