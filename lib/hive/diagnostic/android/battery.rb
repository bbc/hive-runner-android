require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
		class Battery < Diagnostic

			def initialize(config, serial)
				@device = DeviceAPI::Android::ADB
				super(config, serial)
			end

			def battery
			 	self.device.get_battery_info(@serial)
			end
			
			def diagnose
				battery_details = battery
				voltage = battery_details['voltage']
				temperature = battery_details['temperature']
      			if temperature.to_i < config['temperature'].to_i
      				result = self.pass("Temperature: #{temperature}\tVoltage:#{voltage}\n Battery status: OK", "battery")
      			else
      				result = self.fail("Battery overheated. Temperature: #{temperature}\tVoltage:#{voltage}", "battery")
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