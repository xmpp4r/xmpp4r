# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/connection'

module Jabber
  ##
  # The component class provides everything needed to build a XMPP Component.
  #
  # Components are more flexible as they are only restricted in the use of a
  # fixed domain. node and resource of JIDs are freely choosable for all stanzas.
  class Component  < Connection

    # The component's JID
    attr_reader :jid

    # The server's address
    attr_reader :server_address

    # The server's port
    attr_reader :server_port

    # Create a new Component
    # jid:: [JID]
    # server_address:: [String] Hostname
    # server_port:: [Integer] TCP port (5347)
    def initialize(jid, server_address, server_port=5347, threaded = true)
      super(threaded)
      @jid = jid
      @server_address = server_address
      @server_port = server_port
    end
    
    # Connect to the server
    # (chaining-friendly)
    # return:: self
    def connect
      super(@server_address, @server_port)
      self
    end

    ##
    # Close the connection,
    # sends <tt></stream:stream></tt> tag first
    def close
      send("</stream:stream>")
      super
    end

    ##
    # Start the stream-parser and send the component-specific stream opening element
    def start
      super
      send("<stream:stream xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:component:accept' to='#{@jid}' version='1.0'>") { |e|
        if e.name == 'stream'
          true
        else
          false
        end
      }
    end

    ##
    # Send auth with given secret and wait for result
    #
    # Throws AuthenticationFailure
    # secret:: [String] the shared secret 
    def auth(secret)
      hash = Digest::SHA1::new(@streamid.to_s + secret).to_s
      authenticated = false
      send("<handshake>#{hash}</handshake>") { |r|
        if r.prefix == 'stream' and r.name == 'error'
          true
        elsif r.name == 'handshake' and r.namespace == 'jabber:component:accept'
          authenticated = true
          true
        else
          false
        end
      }
      unless authenticated
        raise AuthenticationFailure.new, "Component authentication failed"
      end
    end
  end  
end
