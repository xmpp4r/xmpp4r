# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/connection'

module Jabber
  ##
  # The component class provides everything needed to build a basic XMPP Component.
  class Component  < Connection

    # The component's JID
    attr_reader :jid

    # The server's address
    attr_reader :server_address

    # The server's port
    attr_reader :server_port

    # Create a new Component
    def initialize(jid, server_address, server_port, threaded = true)
      super(server_address, threaded, server_port)
      @jid = jid
      @server_address = server_address
      @server_port = server_port
    end
    
    # Connect to the server
    def connect
      super
      send("<stream:stream xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:component:accept' to='#{@jid}'>") { |e|
        if e.name == 'stream'
          e.consume
        end
      }
      self
    end

    # Send auth with given secret and wait for result
    # secret:: [String] the shared secret 
    # return:: [Boolean] true if auth was successful
    def auth(secret)
      hash = Digest::SHA1::new(@streamid.to_s + secret).to_s
      ok = false
      send("<handshake>#{hash}</handshake>") { |e|
        ok = true if e.name == 'handshake' and e.namespace == 'jabber:component:accept'
        e.consume
      }
      ok
    end
  end  
end
