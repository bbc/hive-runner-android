require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Wifi < Diagnostic

			def device
				@device = DeviceAPI::Android::ADB
			end

			def wifi
				wifi_details = self.device.wifi(@serial)
				return {:status => wifi_details[:status].scan(/^[^\/]*/)[0], :access_point => wifi_details[:access_point]}
			end

			def diagnose
				wifi_status = wifi
				if wifi_status[:status].capitalize == config[:status] 
					result = self.fail('Wifi Disconnected', "wifi")
				else 
					result = self.pass("Wifi connected to '#{wifi_status[:access_point]}'", "wifi")
				end
				result
			end

			def repair(result)
				Hive.logger.info("Trying to repair wifi")
				options = {:serial => @serial, :apk => '/opt/resources/wifi-toggle.apk'}#'/Users/khana46/opt/device_api-android/wifi-toggle.apk'}
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