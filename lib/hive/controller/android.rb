require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      # Uses either DeviceAPI or DeviceDB to generate queue names for a device
      def calculate_queue_names(device)
        if device.is_a? DeviceAPI::Android::Device
          queues = [
              device.model,
              device.manufacturer,
              'android',
              "android-#{device.version}",
              "android-#{device.version}-#{device.model}"
          ]
        else

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
        queues
      end

      def populate_queues(device)
        queues = calculate_queue_names(device)

        # Add the queue prefix if it hase been setup in the config
        queues = queues.map { |a| "#{@config['queue_prefix']}-#{a}"} if @config['queue_prefix']

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
        return queue.first['id'] unless queue.empty? || queue.key?('error')

        queue = create_queue(name, "#{name} queue created by Hive Runner")
        queue['id'] unless queue.empty?
      end

      def create_queue(name, description)
        queue_attributes = {
            name: name,
            description: description
        }

        Hive.devicedb('Queue').register(device_queue: queue_attributes )
      end

      def detect
        devices = DeviceAPI::Android.devices
        Hive.logger.debug('No devices attached') if devices.empty?
        Hive.logger.debug("#{Time.now} Retrieving hive details")
        hive_details = Hive.devicedb('Hive').find(Hive.id)
        Hive.logger.debug("#{Time.now} Finished fetching hive details")

        if hive_details.key?('devices')
          # Update the 'cached' results from DeviceDB
          @hive_details = hive_details
        else
          # DeviceDB isn't available - use the cached version
          hive_details = @hive_details
        end

        if hive_details.is_a? Hash
          # DeviceDB information is available, use it
          hive_details['devices'].select {|a| a['os'] == 'android'}.each do |device|
            registered_device = devices.select { |a| a.serial == device['serial'] && a.status != :unauthorized}
            if registered_device.empty?
              # A previously registered device isn't attached
              Hive.logger.debug("Removing previously registered device - #{device}")
              Hive.devicedb('Device').hive_disconnect(device['id'])
            else
              # A previously registered device is attached, poll it
              Hive.logger.debug("#{Time.now} Polling attached device - #{device}")
              Hive.devicedb('Device').poll(device['id'])
              Hive.logger.debug("#{Time.now} Finished polling device")

              # Make sure that this device has all the queues it should have
              populate_queues(device)

              devices = devices - registered_device
            end
          end

          devices.each do |device|
            register_new_device(device)
          end

          display_devices(hive_details)

          hive_details['devices'].select {|a| a['os'] == 'android'}.collect do |hive_device|
            self.create_device(hive_device)
          end
        else
          # DeviceDB isn't available, use DeviceAPI instead
          device_info = devices.map do |device|
            {'id' =>  device.serial, 'serial' => device.serial, status: 'idle', devices: [{ device_queues: [ calculate_queue_names(device).map { |q| { name: q } } ]}]}
          end

          device_info.collect do |physical_device|
            self.create_device(physical_device)
          end
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
