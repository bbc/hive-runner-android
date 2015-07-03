require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Memory < Diagnostic

        def initialize(config, serial)
          @device = DeviceAPI::Android::ADB
          super(config, serial)
        end

        def memory
          true 
        end

        def diagnose
          memory_status = memory      
        end

        def repair(result)
        end

      end
    end
  end
end