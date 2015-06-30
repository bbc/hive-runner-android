require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Wifi < Diagnostic
				attr_accessor :status, :wifi, :message

				def wifi_status
					@status = DeviceAPI::Android::ADB.wifi(@options['serial'])[:status].scan(/^[^\/]*/)[0]
					@wifi = DeviceAPI::Android::ADB.wifi(@options['serial'])[:wifi]	
				end

				def check_wifi
					begin
      					wifi_status
      					if @status.capitalize == @criteria then
							@message = "#{@status} to #{@wifi}"
							Hive.logger.info("Wifi: #{@wifi} \t Status: #{@status}") 
						else
							Hive.logger.info("Wifi: #{@wifi} \t Status: #{@status}\n Trying Repair")
							repair_wifi
							@message = @status == "CONNECTED" ? "#{@status} to #{@wifi}" : "Wi-Fi Disconnected : #{@wifi}"
						end
					rescue DiagnosticFailed => e
							@log.error("Check Wifi Status failed : " + e.message)
					end
				 record_result("wifi", @status, @message)
			  	end

			  	def repair_wifi
			  		######
			  		# Wifi repair Logic
			  		######
			  			wifi_status
						return true
			 	end
			end
		end
	end
end