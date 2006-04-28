# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module Version
    ##
    # A class to answer version requests using IqQueryVersion
    #
    # This is simplification as one doesn't need dynamic
    # version answering normally.
    #
    # Example usage:
    #  Jabber::Helpers::SimpleVersion.new(my_client, "My cool XMPP4R script", "1.0", "Younicks")
    class SimpleHelper < Helper
      attr_accessor :name
      attr_accessor :version
      attr_accessor :os

      ##
      # Initialize a new version responder
      #
      # Registers it's callback (prio = 180, ref = "Helpers::Version")
      # stream:: [Stream] Where to register callback handlers
      # name:: [String] Software name for answers
      # version:: [String] Software versio for answers
      # os:: [String] Optional operating system name for answers
      def initialize(stream, name, version, os=nil)
        super stream

        @name = name
        @version = version
        @os = os

        add_version_callback(180, "Helpers::SimpleVersion") { |iq,block|
          block.call(@name, @version, @os)
        }
      end
    end
  end
end
