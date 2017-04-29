module Danger
  class DangerCommitLint < Plugin
    class EmptyLineCheck < CommitCheck # :nodoc:
      def message() 'Please separate subject from body with newline.'.freeze end

      def self.type
        :empty_line
      end

      def initialize(message, config = {})
        @empty_line = message[:empty_line]
      end

      def fail?
        @empty_line && !@empty_line.empty?
      end
    end
  end
end
