require 'hive/worker'
require 'hive/messages/android_job'

module Hive
  class Worker
    class Android < Worker

      attr_accessor :device

      def initialize(device)
        begin
          device.merge!({"device_api" => DeviceAPI::Android.device(device['serial'])})
        rescue DeviceAPI::Android::ADBCommandError
          Hive.logger.info("Device disconnected during worker initialization")
        end
        set_device_status('idle')
        self.device = device
        super(device)
      end

      def pre_script(job, file_system, script)
        set_device_status('busy')
        script.set_env "TEST_SERVER_PORT",    @ports[0]

        # TODO: Allow the scheduler to specify the ports to use
        script.set_env "CHARLES_PROXY_PORT",  @ports[1]
        script.set_env "APPIUM_PORT",         @ports[2]
        script.set_env "BOOTSTRAP_PORT",      @ports[3]
        script.set_env "CHROMEDRIVER_PORT",   @ports[4]

        script.set_env 'ADB_DEVICE_ARG', self.device['serial']

        FileUtils.mkdir(file_system.home_path + '/build')
        apk_path = file_system.home_path + '/build/' + 'build.apk'

        script.set_env "APK_PATH", apk_path
        if job.build
          file_system.fetch_build(job.build, apk_path)
          DeviceAPI::Android::Signing.sign_apk({apk: apk_path, resign: true})
        end

        "#{self.device['serial']} #{@ports[2]} #{apk_path} #{file_system.results_path}"
      end

      def job_message_klass
        Hive::Messages::AndroidJob
      end

      def post_script(job, file_system, script)
        @log.info('Post script')
        set_device_status('idle')
      end

      def device_status
        details = Hive.devicedb('Device').find(@options['id'])
        if details.key?('status')
          @state = details['status']
        else
          @state
        end
      end

      def set_device_status(status)
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
