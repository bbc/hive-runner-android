require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
    class Battery < Diagnostic

      def battery
        self.device_api.battery_info
      end
      
      def diagnose
        data = {}
        battery_info = battery
        result = "pass"
        config.keys.each do |c| 
        raise InvalidParameterError.new("Battery Parameter should be any of #{battery_info.keys}") if !battery_info.has_key? c
          begin
            if battery_info[c].to_i < config[c].to_i
              data[:"#{c}"] = battery_info[c]
            else
              data[:"#{c}"] = battery_info[c] 
              result = "fail"
            end
          rescue => e
            Hive.logger.error "Incorrect battery parameter => #{e}"                
            return self.fail("Incorrect parameter #{c} specified. Battery Parameter can be any of #{battery_info.keys}", "Battery") 
          end
        end

        if result != "fail"
          self.pass("Battery", data)
        else
          self.fail("Battery", data)
        end
 
      end

      def repair(result)
        self.fail("Battery temperature above threshold.", "Battery")
      end

    end
    end
  end
end
