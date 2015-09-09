require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Uptime < Diagnostic
        
        def initialize(config, options)
          @next_reboot_time = Time.now + config[:reboot_timeout] if config.has_key?(:reboot_timeout)
          super(config, options)
        end

        def diagnose
          require 'pry'
          binding.pry
          if config.has_key?(:reboot_timeout)
            if Time.now < @next_reboot_time
              self.pass("Time to next reboot: #{@next_reboot_time - Time.now}s", "Reboot")
            else
              self.fail("Reboot required", "Reboot")
            end
          else
            self.pass("Not configured to reboot", "Reboot")
          end
        end
        
        def repair(result)
          Hive.logger.info("Rebooting the device")
          begin  
            self.device_api.reboot
            sleep 30
          rescue
            Hive.logger.error("Device not found")
          end
          @next_reboot_time += config[:reboot_timeout]
          self.pass("Time to next reboot: #{@next_reboot_time - Time.now}s", "Reboot")
        end

      end
    end
  end
end