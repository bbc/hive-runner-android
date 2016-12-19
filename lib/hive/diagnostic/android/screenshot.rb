require 'hive/diagnostic'
module Hive
  class Diagnostic
    class Android
      class Screenshot < Diagnostic
        
        def diagnose
          screenshot_file = Tempfile.new(["#{@device_api.serial}-screenshot", '.png']).path
          @device_api.screenshot(filename: screenshot_file)
          hive_device = Hive.hive_mind.device_details['connected_devices'].select { |d| d['serial'] == @device_api.serial }.first
          Hive.hive_mind.send_screenshot( { device_id: hive_device[:id], screenshot: screenshot_file } ) unless hive_device.nil?
          self.pass('Screenshot captured')
        end
        
        def repair(result)

        end

      end
    end
  end
end
