require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Memory < Diagnostic

        def memory
          @memory = self.device_api.memory unless @memory
          mem = @memory.mem_info
          return {:free => mem.free.split(' ')[0], 
                  :total => mem.total.split(' ')[0], 
                  :used => mem.used.split(' ')[0], }
        end

        def diagnose
          result = nil
          operator = {:free => :>=, :used => :<= , :total => :==}
          memory_status = memory
          if config != nil && config.keys.count != 0
            config.each do |key, value|
              begin
                if memory_status[:"#{key}"].to_i.send(operator[:"#{key}"], value.to_i) 
                  result = self.pass("#{key.capitalize} Memory (#{memory_status[:"#{key}"]}) #{operator[:"#{key}"]} #{value}", "memory" )
                else
                  result = self.fail("Error: #{key.capitalize} Memory (#{memory_status[:"#{key}"]}) is not #{operator[:"#{key}"]} #{value}", "memory")
                  break
                end
              rescue
                Hive.logger.error("Invalid Memory Parameter")
                raise InvalidParameterError.new("Invalid Parameter for memory") if !result
              end
            end 
          else 
            result = self.pass("No parameter specified", "memory")
          end
        result
        end

        def repair(result)
          # Add repair for memory
          self.fail("Cannot repair memory", "memory")
        end

      end
    end
  end
end