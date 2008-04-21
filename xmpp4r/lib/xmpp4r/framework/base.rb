require 'thread'

module Jabber
  module Framework
    class Base

      def self.helper(name, klass=nil, &factory)
        if klass.nil? and factory.nil?
          raise "helper #{name} needs at class or factory"
        end

        define_method(name) do
          @helpers_lock.synchronize do
            if @helpers[name]
              @helpers[name]
            else
              if factory
                @helpers[name] = instance_eval { factory.call(@stream) }
              elsif klass
                @helpers[name] = klass.new(@stream)
              else
                raise
                end
            end
          end
        end
      end

      attr_accessor :stream

      def initialize(stream)
        @stream = stream
        @helpers = {}
        @helpers_lock = Mutex.new
      end

    end
  end
end
