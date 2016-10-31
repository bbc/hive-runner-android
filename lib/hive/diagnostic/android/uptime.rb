require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Uptime < Diagnostic
        
        def diagnose
          if config.has_key?(:reboot_timeout)
            uptime = self.device_api.uptime 
            if  uptime < config[:reboot_timeout]
              self.pass("Time for next reboot: #{config[:reboot_timeout] - uptime}s", "Reboot")
            else
              self.fail("Reboot required", "Reboot")
            end
          else
            self.pass("Not configured for reboot", "Reboot")
          end
        end
        
        def repair(result)
          Hive.logger.info("Rebooting the device")
          begin  
            self.device_api.reboot
          rescue
            Hive.logger.error("Device not found")
          end
          diagnose
        end

      end
    end
  end
end
