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
				wifi_status = wifi
				result = 0
				config.each do |key, value|
					if wifi_status[:"#{key}"].capitalize == value.capitalize 
						result = self.pass("#{key.capitalize} : #{wifi_status[:"#{key}"]}", "wifi" )
					else
						result = self.fail(" Error: #{key.capitalize} : #{wifi_status[:"#{key}"]} ", "wifi")
						break
					end
				end
				result
			end

			def repair(result)
				Hive.logger.info("Trying to repair wifi")
				options = {:serial => @serial, :apk => '/opt/resources/wifi-toggle.apk'}
				self.device.install_apk(options)
				self.device.am(@serial, "-n com.wifi.togglewifi/.MainActivity -e wifi true")
				sleep 5 
				self.device.uninstall_apk(:serial => @serial, :package_name => 'com.wifi.togglewifi')
				diagnose
			end
	
			end
		end
	end
end