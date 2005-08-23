#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

require 'xmpp4r/iq'
require 'xmpp4r/iqqueryversion'

module Jabber
  ##
  # A class to answer version requests
  # utilizing IqQueryVersion
  #
  # This is simplification as one doesn't need dynamic
  # version answering normally.
  class VersionResponder
    attr_accessor :name
    attr_accessor :version
    attr_accessor :os

    ##
    # Initialize a new version responder
    # stream:: [Stream] Where to register callback handlers
    # name:: [String] Software name for answers
    # version:: [String] Software versio for answers
    # os:: [String] Optional operating system name for answers
    # priority:: [Integer] Priority for callbacks
    # ref:: [String] Reference for callbacks
    def initialize(stream, name, version, os=nil, priority=0, ref=nil)
      @stream = stream

      @name = name
      @version = version
      @os = os

      stream.add_iq_callback(priority, ref) { |iq|
        iq_callback(iq)
      }
    end

    ##
    # <iq/> callback handler to answer Software Version queries
    # (registered by constructor and used internally only)
    def iq_callback(iq)
      if iq.type == :get
        if iq.query.kind_of?(IqQueryVersion)
          iq.consume

          iq.from, iq.to = iq.to, iq.from
          iq.type = :result
          iq.query.set_iname(@name).set_version(@version).set_os(@os)

          @stream.send(iq)
        end
      end
    end
  end
end
