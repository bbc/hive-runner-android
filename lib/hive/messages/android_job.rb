require 'hive/messages'

module Hive
  module Messages
    class AndroidJob < Hive::Messages::Job
      def build
        self.target.symbolize_keys[:build]
      end

      def resign
        self.target.symbolize_keys[:resign] != 0
      end
    end
  end
end
