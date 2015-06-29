require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Wifi < Diagnostic
				def check_wifi
      			# Should check using device_api-android
      				begin
      					status = DeviceAPI::Android::ADB.wifi(@options['serial'])[:status].scan(/^[^\/]*/)[0]
						wifi = DeviceAPI::Android::ADB.wifi(@options['serial'])[:wifi]
						Hive.logger.info("Wifi: #{wifi} \t Status: #{status}")
						rescue DiagnosticFailed => e
        		    	@log.info("#{e.message}\n");
					end
				#record_result(status,message)
    		  	end

			end
		end
	end
end