# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
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
    def initialize(jid, threaded = true)
      super(threaded)
      @jid = jid
    end

    ##
    # connect to the server
    # (chaining-friendly)
    # host:: [String] Optional c2s host, will be extracted from jid if nil
    # return:: self
    def connect(host = nil, port = 5222)
      super(host.nil? ? jid.domain : host, port)
      send("<stream:stream xmlns:stream='http://etherx.jabber.org/streams' xmlns='jabber:client' to='#{@jid.domain}'>") { |b| 
        # TODO sanity check : is b a stream ? get version, etc.
        true
      }
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

    ##
    # Change the client's password
    #
    # Threading is suggested, as this code waits
    # for an answer.
    #
    # Raises an exception upon error response.
    # new_password:: [String] New password
    def password=(new_password)
      iq = Iq::new_query(:set, @jid.domain)
      iq.query.add_namespace('jabber:iq:register')
      iq.query.add(REXML::Element.new('username')).text = @jid.node
      iq.query.add(REXML::Element.new('password')).text = new_password

      err = nil
      send_with_id(iq) { |answer|
        if answer.type == :result
          true
        elsif answer.type == :error
          err = "Error changing password: #{answer.error}, #{answer.text}"
          true
        else
          false
        end
      }

      raise err unless err.nil?
    end
  end  
end
