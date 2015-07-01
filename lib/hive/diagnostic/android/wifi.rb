require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Wifi < Diagnostic
				attr_accessor :status, :wifi, :message

        def diagnose
          self.fail( :message => 'WIFI on wrong network', {} )
          self.pass( :message => 'WIFI is fine' )
        end
        
        def repair(result)
          result.passed!
        end

				def wifi_status
				end

				def diagnose
				  
				  wifi_status = self.device.wifi
					
					result
					
					if wifi_status['blah']
					  result = self.fail( :message => 'Wifi not connected' )
				  elsif wifi_status['ap'] == config['ap']
				    result = self.fail( :message => 'Wrong access point' )
				  end
				  
				  result = self.pass(:message => 'Wifi ok') if !result
				  result
			end
		end
	end
end
