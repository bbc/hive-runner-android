require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Memory < Diagnostic

        def memory
          @memory = self.device_api.memory unless @memory
          mem = @memory.mem_info
          return {:free => mem.free.split(' ').first, 
                  :total => mem.total.split(' ').first, 
                  :used => mem.used.split(' ').first, }
        end

        def diagnose
          data = {}
          result = "pass"
          operator = {:free => :>=, :used => :<= , :total => :==}
          memory_status = memory
          config.each do |key, value|
            raise InvalidParameterError.new("Battery Parameter should be any of ':free', ':used', ':total'") if !memory_status.has_key? key.to_sym
            data[:"#{key}_memory"] = {:value => memory_status[:"#{key}"], :unit => "kB"}
            result = "fail" if !memory_status[:"#{key}"].to_i.send(operator[:"#{key}"], value.to_i)
          end 

          if result != "pass"
            self.fail("Memory", data)  
          else
            self.pass("Memory", data)  
          end
        end

        def repair(result)
          # Add repair for memory
          self.fail("Cannot repair memory")
        end

      end
    end
  end
end
