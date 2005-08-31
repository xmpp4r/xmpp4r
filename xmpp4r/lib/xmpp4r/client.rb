# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/connection'

module Jabber

  # The client class provides everything needed to build a basic XMPP Client.
  class Client  < Connection

    # The client's JID
    attr_reader :jid

    # Create a new Client. If threaded mode is activated, callbacks are called
    # as soon as messages are received; If it isn't, you have to call
    # Stream#process from time to time.
    # TODO SSL mode is not implemented yet.
    def initialize(jid, threaded = true, ssl = false)
      super(jid.domain, threaded, ssl ? 5223 : 5222)
      @jid = jid
    end

    ##
    # connect to the server
    def connect
      super
      send("<stream:stream xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:client' to='#{@host}'>") { |b| 
        # TODO sanity check : is b a stream ? get version, etc.
        b.consume
      }
    end

    ##
    # Send auth with given password and wait for result
    # password:: [String] the password
    # digest:: [Boolean] use Digest authentication
    # return:: [Boolean] true if auth was successful
    def auth(password, digest=true)
      authset = nil
      if digest
        authset = Iq::new_authset_digest(@jid, @streamid.to_s, password)
      else
        authset = Iq::new_authset(@jid, password)
      end
      res = false
      send(authset) do |r|
        if r.kind_of?(Iq) and r.type == :result
          res = true
          r.consume
        elsif r.kind_of?(Iq) and r.type == :error
          res = false
          r.consume
        end
      end
      $defout.flush
      res
    end
  end  
end
