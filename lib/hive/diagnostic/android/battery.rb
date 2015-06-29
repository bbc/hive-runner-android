require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Battery < Diagnostic
				def check_battery
      		# Should check using device_api-android
  		    		begin
      					temperature = DeviceAPI::Android::ADB.get_battery_info(@options['serial'])['temperature']
      					voltage = DeviceAPI::Android::ADB.get_battery_info(@options['serial'])['voltage']
      					Hive.logger.info("Battery Temperature: #{temperature} and Voltage: #{voltage} ")
      				rescue DiagnosticFailed => e
      		    	  	@log.info("#{e.message}\n");
      		    	  	#record_result(status,message)
        			end
      			end

			end
		end
	end
end