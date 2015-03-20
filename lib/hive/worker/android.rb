require 'hive/worker'
require 'hive/messages/android_job'

module Hive
  class PortReserver
    attr_accessor :ports
    def initialize
      self.ports = {}
    end

    def reserve(queue_name: 'default')
      self.ports[queue_name] = Hive.data_store.port.assign("#{queue_name}")
      #@log.info("#{queue_name} port: #{@ports[queue_name]}")
      self.ports[queue_name]
    end
  end

  class Worker
    class Android < Worker

      attr_accessor :device

      def initialize(device)
        @ports = PortReserver.new
        @adb_server_port = Hive.data_store.port.assign("#{device['name']} - adb")
        #@log.info("ADB server port: #{@adb_server_port}")
        self.device = device
        super(device)
      end

      def pre_script(job, job_paths, script)
        script.set_env "TEST_SERVER_PORT", @adb_server_port

        script.set_env "CHARLES_PROXY_PORT",  @ports.reserve(queue_name: 'Charles')
        script.set_env "APPIUM_PORT",         @ports.reserve(queue_name: 'Appium')
        script.set_env "BOOTSTRAP_PORT",      @ports.reserve(queue_name: 'Bootstrap')
        script.set_env "CHROMEDRIVER_PORT",   @ports.reserve(queue_name: 'Chromedriver')

        script.set_env 'QUEUE_NAME', job.execution_variables.queue_name
        script.set_env 'ADB_DEVICE_ARG', self.device['serial']

        FileUtils.mkdir(job_paths.home_path + '/build')
        apk_path = job_paths.home_path + '/build/' + 'build.apk'

        script.set_env "APK_PATH", apk_path
        script.fetch_build(job.build, apk_path) if job.build

        # add a step to resign the build, usually needed
        script.append_bash_cmd "calabash-android resign #{apk_path}" if job.build

        "#{self.device['serial']} #{@ports.ports['Appium']} #{apk_path} #{job_paths.results_path}"
      end

      def job_message_klass
        Hive::Messages::AndroidJob
      end

      def post_script(job, job_paths, script)
        @log.info('Post script')
        @ports.ports.each do |name, port|
          Hive.data_store.port.release(port)
        end
      end

      def device_status
        details = Hive.devicedb('Device').find(@options['id'])
        @log.info("Device details: #{details.inspect}")
        details['status']
      end
    end
  end
end
