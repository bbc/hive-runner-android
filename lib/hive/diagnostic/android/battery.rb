require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
    class Battery < Diagnostic

      def battery
        self.device_api.battery_info
      end
      
      def diagnose
        result = nil
        battery_info = battery
        config.keys.each do |c| 
        raise InvalidParameterError.new("Battery Parameter should be any of #{battery_info.keys}") if !battery_info.has_key? c
          begin
            if battery_info[c].to_i < config[c].to_i
               result = self.pass("Current #{c} is #{battery_info[c]}")
            else
               result = self.fail("Actual #{c}: is #{battery_info[c]} which is above threshold")
            end
          rescue
            result = self.fail("Incorrect parameter #{c} specified. Battery Parameter can be any of #{battery_info.keys}")                
          end
        end
      end

      def repair(result)
        result = self.fail("Battery temperature above threshold.", "battery")
      end
    end
    end
  end
end
