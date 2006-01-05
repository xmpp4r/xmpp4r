# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/stream'

module Jabber
  ##
  # The connection class manages the TCP connection to the Jabber server
  #
  class Connection  < Stream
    attr_reader :host, :port, :input, :output

    ##
    # Create a new connection to the given host and port, using threaded mode
    # or not.
    def initialize(threaded = true)
      super(threaded)
      @host = nil
      @port = nil
    end

    ##
    # Connects to the Jabber server through a TCP Socket and
    # starts the Jabber parser.
    #
    def connect(host, port)
      @host = host
      @port = port

      Jabber::debuglog("CONNECTING:\n#{@host}:#{@port}")
      @socket = TCPSocket.new(@host, @port)
      start(@socket)
    end
  end  
end
