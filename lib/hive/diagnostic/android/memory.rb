require 'hive/diagnostic'
module Hive
	class Diagnostic
		class Android
			class Memory < Diagnostic
				
    		  	def check_memory
    	  			begin
    	  			# Should check using device_api-android
   		   			rescue DiagnosticFailed => e
    	        	@log.info("#{e.message}\n");
   		        	#record_result(status,message)
   			   		end
   			   	end
			end
		end
	end
end