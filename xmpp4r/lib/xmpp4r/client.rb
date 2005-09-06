# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/connection'
require 'xmpp4r/authenticationfailure'

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
    # (chaining-friendly)
    # return:: self
    def connect
      super
      send("<stream:stream xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:client' to='#{@host}'>") { |b| 
        # TODO sanity check : is b a stream ? get version, etc.
        true
      }
      self
    end

    ##
    # Send auth with given password and wait for result
    #
    # Throws AuthenticationFailure
    # password:: [String] the password
    # digest:: [Boolean] use Digest authentication
    def auth(password, digest=true)
      authset = nil
      if digest
        authset = Iq::new_authset_digest(@jid, @streamid.to_s, password)
      else
        authset = Iq::new_authset(@jid, password)
      end
      authenticated = false
      send(authset) do |r|
        if r.kind_of?(Iq) and r.type == :result
          authenticated = true
          true
        elsif r.kind_of?(Iq) and r.type == :error
          true
        else
          false
        end
      end
      $defout.flush
      unless authenticated
        raise AuthenticationFailure.new, "Client authentication failed"
      end
    end
  end  
end
