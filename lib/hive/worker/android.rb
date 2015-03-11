require 'hive/worker'
require 'hive/messages/android_job'

module Hive
  class Worker
    class Android < Worker

      def initialize(device)
        @adb_server_port = Hive.data_store.port.assign("#{device['name']} - adb")
        #@log.info("ADB server port: #{@adb_server_port}")
        binding.pry
        super(device)
      end

      def pre_script(job, job_paths, script)
        binding.pry
        script.set_env "TEST_SERVER_PORT", @adb_server_port

        @charles_port = Hive.data_store.port.assign("#{device['name']} - charles")
        @log.info("Charles port: #{@charles_port}")
        script.set_env "CHARLES_PROXY_PORT", @charles_port

        @appium_port = Hive.data_store.port.assign("#{device['name']} - appium")
        @log.info("Appium port: #{@appium_port}")
        script.set_env "APPIUM_PORT", @appium_port

        @bootstrap_port = Hive.data_store.port.assign("#{device['name']} - bootstrap")
        @log.info("Bootstrap port: #{@bootstrap_port}")
        script.set_env "BOOTSTRAP_PORT", @bootstrap_port

        @chromedriver_port = Hive.data_store.port.assign("#{device['name']} - chromedriver")
        @log.info("Chromedriver port: #{@chromedriver_port}")
        script.set_env "CHROMEDRIVER_PORT", @chromedriver_port

        script.set_env 'QUEUE_NAME', self.device.queue

        fetch_build(job.build, apk_path) if job.build

        # add a step to resign the build, usually needed
        script.append_bash_cmd "calabash-android resign #{apk_path}" if job.build

        script.append_bash_cmd job.command

        "#{self.device.serial_number} #{@appium_port} #{apk_path} #{job_paths.results_path}"
      end

      def job_message_klass
        Hive::Messages::AndroidJob
      end

      def post_script(job, job_paths, script)
        @log.info('Post script')
        [@charles_port, @appium_port, @bootstrap_port, @chromedriver_port].each do |p|
          Hive.data_store.port.release(p)
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