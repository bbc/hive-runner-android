require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Memory < Diagnostic

        def memory
          mem = self.device_api.memory.mem_info
          return {:free => mem.free.split(' ')[0], 
                  :total => mem.total.split(' ')[0], 
                  :used => mem.used.split(' ')[0], }
        end

        def diagnose
          result = nil
          operator = {:free => :>, :used => :< , :total => :==}
          memory_status = memory
          begin
            if config != nil && config.keys.count != 0
              config.each do |key, value|
                  if memory_status[:"#{key}"].to_i.send(operator[:"#{key}"], value.to_i) 
                  result = self.pass("#{key.capitalize} : #{memory_status[:"#{key}"]}", "memory" )
                  else
                   result = self.fail("Error: #{key.capitalize} : #{memory_status[:"#{key}"]} ", "memory")
                   break
                  end
               end 
            else 
              result = self.pass("No parameter specified", "memory")
            end
          
          rescue
            Hive.logger.error("Invalid Memory Parameter")
          raise InvalidParameterError.new("Invalid Memory Parameter") if !result 
        result  
        end
        end

        def repair(result)
        end

      end
    end
  end
end