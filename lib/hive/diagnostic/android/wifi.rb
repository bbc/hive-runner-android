require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
    class Wifi < Diagnostic

      def wifi
        wifi_details = self.device_api.wifi_status
        return {:status => wifi_details[:status].scan(/^[^\/]*/)[0], :access_point => wifi_details[:access_point]}
      end

      def diagnose
      result = nil
      wifi_status = wifi
      config.each do |key, value|
        if config != nil && config.keys.count != 0
          begin
            if wifi_status[:"#{key}"].capitalize == value.capitalize 
              result = self.pass("#{key.capitalize} : #{wifi_status[:"#{key}"]}", "wifi" )
            else
              result = self.fail(" Error: #{key.capitalize} : #{wifi_status[:"#{key}"]} ", "wifi")
              break
            end
          rescue 
            Hive.logger.error("Invalid Parameter for Wifi #{key}")
            raise InvalidParameter.new("Invalid Wifi Parameter for Wifi: #{key}") if !result
          end
        else
          result = self.pass("No parameter specified", "wifi")
        end
      end
      result
      end 

      def repair(result)
        Hive.logger.info("Trying to repair wifi")
        options = {:apk => '/path/to/apk/to/toggle/wifi', :package => '/pkg/name/ex: com.wifi.togglewifi'} 
        begin
          self.device_api.install(options[:apk])
          self.device_api.start_intent("-n com.wifi.togglewifi/.MainActivity -e wifi true")
          sleep 5 
          self.device_api.uninstall(options[:package])
        rescue
          Hive.logger.error("Unable to fix wifi issue")
        end
        diagnose
      end
  
    end
    end
  end
end