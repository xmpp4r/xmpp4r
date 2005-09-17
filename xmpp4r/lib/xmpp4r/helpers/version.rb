# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'
require 'xmpp4r/iq/query/version'

module Jabber
  module Helpers
    ##
    # A class to answer version requests
    # utilizing IqQueryVersion
    #
    # This is simplification as one doesn't need dynamic
    # version answering normally.
    #
    # Example usage:
    #  Jabber::Helpers::Version.new(my_client, "My cool XMPP4R script", "1.0", "Younicks")
    class Version
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
        @stream = stream

        @name = name
        @version = version
        @os = os

        stream.add_iq_callback(180, "Helpers::Version") { |iq|
          iq_callback(iq)
        }
      end

      ##
      # <iq/> callback handler to answer Software Version queries
      # (registered by constructor and used internally only)
      #
      # Used internally
      def iq_callback(iq)
        if iq.type == :get
          if iq.query.kind_of?(IqQueryVersion)
            iq.from, iq.to = iq.to, iq.from
            iq.type = :result
            iq.query.set_iname(@name).set_version(@version).set_os(@os)

            @stream.send(iq)

            true
          end
        end
      end
    end
  end
end
