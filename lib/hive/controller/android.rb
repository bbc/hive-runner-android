require 'hive/controller'
require 'hive/worker/android'
require 'device_api/android'

module Hive
  class Controller
    class Android < Controller

      def detect
        self.detect_hive_mind
        self.detect_devicedb
      end

      def detect_hive_mind
        devices = DeviceAPI::Android.devices
        Hive.logger.debug('HM) No devices attached') if devices.empty?

        if not Hive.hive_mind.device_details.has_key? :error
          # Checking device_type for 'Mobile'
          # TODO Check for os to ensure Android
          connected_devices = Hive.hive_mind.device_details['connected_devices'].select{ |d| d['device_type'] == 'Mobile' }

          to_poll = []
          attached_devices = []
          connected_devices.each do |device|
            Hive.logger.debug("HM) Device details: #{device.inspect}")
            registered_device = devices.select { |a| a.serial == device['serial'] && a.status != :unauthorized }
            if registered_device.empty?
              # A previously registered device isn't attached
              Hive.logger.debug("HM) Removing previously registered device - #{device}")
              Hive.hive_mind.disconnect(device['id'])
            else
              # A previously registered device is attached, poll it
              Hive.logger.debug("HM) Setting #{device} to be polled")
              Hive.logger.info("HM) Stuff: #{registered_device.inspect}")
              attached_devices << self.create_device(device.merge('os_version' => registered_device[0].version))
              to_poll << device['id']

              devices = devices - registered_device
            end
          end

          # Poll already registered devices
          Hive.logger.debug("HM) Polling: #{to_poll}")
          Hive.hive_mind.poll(*to_poll)

          # Register new devices
          devices.select{|a| a.status != :unauthorized}.each do |device|
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
                  hive_id: Hive.id
              )
              Hive.hive_mind.connect(dev['id'])
              Hive.logger.info("HM) Device registered: #{dev}")
            rescue DeviceAPI::DeviceNotFound => e
              Hive.logger.warn("HM) Device disconnected before registration (serial: #{device.serial})")
            end
          end

        else
          Hive.logger.info('HM) No Hive Mind connection')
          # Hive Mind isn't available, use DeviceAPI instead
          device_info = devices.select { |a| a.status != :unauthorized }.map do |device|
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

# Old code

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

        # Add the queue prefix if it has been setup in the config
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

        return queue.first['id'] unless queue.empty? || queue.is_a?(Hash)

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

      def detect_devicedb
        devices = DeviceAPI::Android.devices
        Hive.logger.debug('No devices attached') if devices.empty?
        Hive.logger.debug("#{Time.now} Retrieving hive details")
        hive_details = Hive.devicedb('Hive').find(Hive.id)
        Hive.logger.debug("#{Time.now} Finished fetching hive details")
        attached_devices = []

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
              attached_devices << self.create_device(device.merge('os_version' => registered_device[0].version, 'model' => device['device_model'], 'brand' => device['device_brand']))
            end
          end

          devices.each do |device|
            register_new_device(device)
          end

          display_devices(hive_details)

          #hive_details['devices'].select {|a| a['os'] == 'android'}.collect do |hive_device|
          #  self.create_device(hive_device)
          #end
        else
          # DeviceDB isn't available, use DeviceAPI instead
#          device_info = devices.map do |device|
#            {'id' =>  device.serial, 'serial' => device.serial, status: 'idle', devices: [{ device_queues: [ calculate_queue_names(device).map { |q| { name: q } } ]}]}
#          end

          device_info = devices.select { |a| a.status != :unauthorized }.map do |device|
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

#          device_info.collect do |physical_device|
#            self.create_device(physical_device)
#          end
        end
        attached_devices
      end

      def register_new_device(device)
        begin
          Hive.logger.info("Adding new Android device: #{device.model}")

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
        rescue DeviceAPI::DeviceNotFound
          Hive.logger.info("Device '#{device.serial}' disconnected during registration")
        rescue DeviceAPI::UnauthorizedDevice
          Hive.logger.info("Device '#{device.serial}' is unauthorized")
        rescue DeviceAPI::Android::ADBCommandError
          # If a device has been disconnected while we're trying to add it, the device_api
          # gem will throw an error
          Hive.logger.debug('Device disconnected while attempting to add')
        rescue => e
          Hive.logger.warn("Error with connected device: #{e.message}")
        end

        registration = Hive.devicedb('Device').register(attributes)
        Hive.devicedb('Device').hive_connect(registration['id'], Hive.id)
      end

# End of old code

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
