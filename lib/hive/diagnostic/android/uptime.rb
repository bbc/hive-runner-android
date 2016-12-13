require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Uptime < Diagnostic
        
        def diagnose(data={})
          if config.has_key?(:reboot_timeout)
            uptime = self.device_api.uptime 
            if  uptime < config[:reboot_timeout]
              data[:next_reboot_in] = {:value => "#{config[:reboot_timeout] - uptime}", :unit => "s"}
              self.pass("Time for next reboot: #{config[:reboot_timeout] - uptime}s", data)
            else
              self.fail("Reboot required", data)
            end
          else
            data[:reboot] = "Not configured"
            self.pass("Not configured for reboot", data)
          end
        end
        
        def repair(result)
          data = {}
          Hive.logger.info("Rebooting the device")
          begin  
#            self.device_api.reboot
            data[:last_rebooted] = {:value => Time.now}
          rescue
            Hive.logger.error("Device not found")
          end
          diagnose(data)
        end

      end
    end
  end
end
