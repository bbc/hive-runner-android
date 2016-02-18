require 'hive/worker'
require 'hive/messages/android_job'

module Hive
  class PortReserver
    attr_accessor :ports
    def initialize
      self.ports = {}
    end

    def reserve(queue_name)
      self.ports[queue_name] = yield
      self.ports[queue_name]
    end
  end

  class Worker
    class Android < Worker

      attr_accessor :device

      def initialize(device)
        @worker_ports = PortReserver.new
        begin
          device.merge!({"device_api" => DeviceAPI::Android.device(device['serial'])})
        rescue DeviceAPI::DeviceNotFound
          Hive.logger.info("Device '#{device['serial']}' disconnected during initialization")
        rescue DeviceAPI::UnauthorizedDevice
          Hive.logger.info("Device '#{device['serial']}' is unauthorized")
        rescue DeviceAPI::Android::ADBCommandError
          Hive.logger.info("Device disconnected during worker initialization")
        rescue => e
          Hive.logger.warn("Error with connected device: #{e.message}")
        end
        set_device_status('idle')
        self.device = device
        super(device)
      end

      def adb_port
        # Assign adb port for this worker
        return @adb_port unless @adb_port.nil?
        @adb_port = @port_allocator.allocate_port
      end

      def pre_script(job, file_system, script)
        set_device_status('busy')
        script.set_env "TEST_SERVER_PORT",    adb_port

        # TODO: Allow the scheduler to specify the ports to use
        script.set_env "CHARLES_PROXY_PORT",  @worker_ports.reserve(queue_name: 'Charles') { @port_allocator.allocate_port }
        script.set_env "APPIUM_PORT",         @worker_ports.reserve(queue_name: 'Appium') { @port_allocator.allocate_port }
        script.set_env "BOOTSTRAP_PORT",      @worker_ports.reserve(queue_name: 'Bootstrap') { @port_allocator.allocate_port }
        script.set_env "CHROMEDRIVER_PORT",   @worker_ports.reserve(queue_name: 'Chromedriver') { @port_allocator.allocate_port }

        script.set_env 'ADB_DEVICE_ARG', self.device['serial']

        FileUtils.mkdir(file_system.home_path + '/build')
        apk_path = file_system.home_path + '/build/' + 'build.apk'

        script.set_env "APK_PATH", apk_path
        if job.build
          file_system.fetch_build(job.build, apk_path)
          DeviceAPI::Android::Signing.sign_apk({apk: apk_path, resign: true})
        end

        DeviceAPI::Android.device(device['serial']).unlock

        "#{self.device['serial']} #{@worker_ports.ports['Appium']} #{apk_path} #{file_system.results_path}"
      end

      def job_message_klass
        Hive::Messages::AndroidJob
      end

      def post_script(job, file_system, script)
        @log.info('Post script')
        @worker_ports.ports.each do |name, port|
          @port_allocator.release_port(port)
        end
        set_device_status('idle')
      end

      def device_status
        # TODO Get from Hive Mind
        details = Hive.devicedb('Device').find(@options['id'])
        if details.key?('status')
          @state = details['status']
        else
          @state
        end
      end

      def set_device_status(status)
        # TODO Report to Hive Mind
        @state = status
        begin
          details = Hive.devicedb('Device').poll(@options['id'], status)
          if details.key?('status')
            details['status']
          else
            @state
          end
        rescue
          @state
        end
      end
    end
  end
end
