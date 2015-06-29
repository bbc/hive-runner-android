require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Wifi < Diagnostic
				def check_wifi
      				begin
      					status = DeviceAPI::Android::ADB.wifi(@options['serial'])[:status].scan(/^[^\/]*/)[0]
						wifi = DeviceAPI::Android::ADB.wifi(@options['serial'])[:wifi]
						message = status == "CONNECTED" ? "#{status} to #{wifi}" : "Disconnected from wifi: #{wifi}" 
						record_result("wifi", status, message)
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