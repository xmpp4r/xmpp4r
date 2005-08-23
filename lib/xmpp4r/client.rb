#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

require 'thread'
require 'xmpp4r/connection'
require 'xmpp4r/jid'

module Jabber

  ##
  # The client class provides everything needed to build a basic XMPP Client.
  #
  class Client  < Connection

    ##
    # The client's JID
    attr_reader :jid

    ##
    # Create a new Client
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
      send(authset) { |r|
        if r.kind_of?(Iq) and r.type == :result
          res = true
          r.consume
        elsif r.kind_of?(Iq) and r.type == :error
          res = false
          r.consume
        end
      }
      $defout.flush
      res
    end
  end  
end
