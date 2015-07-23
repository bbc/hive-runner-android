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
			begin
				if config != nil && config.keys.count != 0	
					temperature = battery_info['temperature']
					if temperature.to_i < config['temperature'].to_i
						result = self.pass("Temperature: #{temperature}\n Battery status: OK", "battery")
					else
						result = self.fail("Battery overheated. Temperature: #{temperature} ", "battery")
					end
				else
					result = self.pass("No parameter specified for battery", "battery")
				end
			rescue
            	Hive.logger.error("Invalid Battery Parameter")
          		raise InvalidParameterError.new("Invalid Parameter for battery") if !result
          	end
			result
			end

			def repair(result)
				diagnose
			end
		end
		end
	end
end