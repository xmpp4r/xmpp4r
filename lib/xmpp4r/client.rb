# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io

require 'resolv'
require 'xmpp4r/connection'
require 'xmpp4r/sasl'

module Jabber

  # The client class provides everything needed to build a basic XMPP
  # Client.
  #
  # If you want your connection to survive disconnects and timeouts,
  # catch exception in Stream#on_exception and re-call Client#connect
  # and Client#auth. Don't forget to re-send initial Presence and
  # everything else you need to setup your session.
  class Client  < Connection

    # The client's JID
    attr_reader :jid

    ##
    # Create a new Client.
    #
    # Remember to *always* put a resource in your JID unless the server can do SASL.
    def initialize(jid)
      super()
      @jid = (jid.kind_of?(JID) ? jid : JID.new(jid.to_s))
      @authenticated = false
    end

    ##
    # connect to the server
    # (chaining-friendly)
    #
    # If you omit the optional host argument SRV records for your jid will
    # be resolved. If none works, fallback is connecting to the domain part
    # of the jid.
    # host:: [String] Optional c2s host, will be extracted from jid if nil
    # port:: [Fixnum] The server port (default: 5222)
    # return:: self
    def connect(host = nil, port = 5222, proxy_host = nil, proxy_port = nil)
      if host.nil?
        begin
          srv = []
          Resolv::DNS.open { |dns|
            # If ruby version is too old and SRV is unknown, this will raise a NameError
            # which is caught below
            Jabber::debuglog("RESOLVING:\n_xmpp-client._tcp.#{@jid.domain} (SRV)")
            srv = dns.getresources("_xmpp-client._tcp.#{@jid.domain}", Resolv::DNS::Resource::IN::SRV)
          }
          # Sort SRV records: lowest priority first, highest weight first
          srv.sort! { |a,b| (a.priority != b.priority) ? (a.priority <=> b.priority) : (b.weight <=> a.weight) }

          srv.each { |record|
            begin
              connect(record.target.to_s, record.port)
              # Success
              return self
            rescue SocketError, Errno::ECONNREFUSED
              # Try next SRV record
            end
          }
        rescue NameError
          Jabber::debuglog "Resolv::DNS does not support SRV records. Please upgrade to ruby-1.8.3 or later!"
        end
        # Fallback to normal connect method
      end

      super(host.nil? ? jid.domain : host, port, proxy_host, proxy_port)
      self
    end

    ##
    # Close the connection,
    # sends <tt></stream:stream></tt> tag first
    def close
      if @status == CONNECTED
        send("</stream:stream>")
      end
      super
    end

    ##
    # Start the stream-parser and send the client-specific stream opening element
    def start
      super
      send(generate_stream_start(@jid.domain)) { |e|
        if e.name == 'stream'
          true
        else
          false
        end
      }
    end

    ##
    # Authenticate with the server
    #
    # Throws ClientAuthenticationFailure
    #
    # Authentication mechanisms are used in the following preference:
    # * SASL DIGEST-MD5
    # * SASL PLAIN
    # * Non-SASL digest
    # password:: [String]
    def auth(password)
      begin
        if @stream_mechanisms.include? 'DIGEST-MD5'
          auth_sasl SASL.new(self, 'DIGEST-MD5'), password
        elsif @stream_mechanisms.include? 'PLAIN'
          auth_sasl SASL.new(self, 'PLAIN'), password
        else
          auth_nonsasl(password)
        end
        @authenticated = true
      rescue
        Jabber::debuglog("#{$!.class}: #{$!}\n#{$!.backtrace.join("\n")}")
        raise ClientAuthenticationFailure.new, $!.to_s
      end
    end

    ##
    # Resource binding (RFC3920bis-06 - section 8.)
    #
    # XMPP allows to bind to multiple resources
    def bind(desired_resource=nil)
      iq = Iq.new(:set)
      bind = iq.add REXML::Element.new('bind')
      bind.add_namespace @stream_features['bind']
      if desired_resource
        resource = bind.add REXML::Element.new('resource')
        resource.text = desired_resource
      end

      jid = nil
      semaphore = Semaphore.new
      send_with_id(iq) do |reply|
        reply_bind = reply.first_element('bind')
        if reply_bind
          reported_jid = reply_bind.first_element('jid')
          if reported_jid and reported_jid.text
            jid = JID.new(reported_jid.text)
          end
        end
        semaphore.run
      end
      semaphore.wait
      jid
    end

    ##
    # Resource unbinding (RFC3920bis-06 - section 8.6.3.)
    def unbind(desired_resource)
      iq = Iq.new(:set)
      unbind = iq.add REXML::Element.new('unbind')
      unbind.add_namespace @stream_features['unbind']
      resource = unbind.add REXML::Element.new('resource')
      resource.text = desired_resource

      send_with_id(iq)
    end

    ##
    # Use a SASL authentication mechanism and bind to a resource
    #
    # If there was no resource given in the jid, the jid/resource
    # generated by the server will be accepted.
    #
    # This method should not be used directly. Instead, Client#auth
    # may look for the best mechanism suitable.
    # sasl:: Descendant of [Jabber::SASL::Base]
    # password:: [String]
    def auth_sasl(sasl, password)
      sasl.auth(password)

      # Restart stream after SASL auth
      restart
      # And wait for features - again
      @features_sem.wait

      # Resource binding (RFC3920 - 7)
      if @stream_features.has_key? 'bind'
        Jabber::debuglog("**********Handling bind")
        @jid = bind(@jid.resource)
      end

      # Session starting
      if @stream_features.has_key? 'session'
        iq = Iq.new(:set)
        session = iq.add REXML::Element.new('session')
        session.add_namespace @stream_features['session']

        semaphore = Semaphore.new
        send_with_id(iq) {
          semaphore.run
        }
        semaphore.wait
      end
    end

    def restart
      stop
      start
    end

    ##
    # See Client#auth_anonymous_sasl
    def auth_anonymous
      auth_anonymous_sasl
    end


    ##
    # Shortcut for anonymous connection to server
    #
    # Throws ClientAuthenticationFailure
    def auth_anonymous_sasl
      if self.supports_anonymous?
        begin
          auth_sasl SASL.new(self, 'ANONYMOUS'), ""
        rescue
          Jabber::debuglog("#{$!.class}: #{$!}\n#{$!.backtrace.join("\n")}")
          raise ClientAuthenticationFailure, $!.to_s
        end
      else
        raise ClientAuthenticationFailure, 'Anonymous authentication unsupported'
      end
    end

    ##
    # Reports whether or not anonymous authentication is reported
    # by the client.
    #
    # Returns true or false
    def supports_anonymous?
      @stream_mechanisms.include? 'ANONYMOUS'
    end

    ##
    # Send auth with given password and wait for result
    # (non-SASL)
    #
    # Throws ServerError
    # password:: [String] the password
    # digest:: [Boolean] use Digest authentication
    def auth_nonsasl(password, digest=true)
      authset = nil
      if digest
        authset = Iq.new_authset_digest(@jid, @streamid.to_s, password)
      else
        authset = Iq.new_authset(@jid, password)
      end
      send_with_id(authset)
      $>.flush

      true
    end

    ##
    # Get instructions and available fields for registration
    # return:: [instructions, fields] Where instructions is a String and fields is an Array of Strings
    def register_info
      instructions = nil
      fields = []

      reg = Iq.new_registerget
      reg.to = jid.domain
      send_with_id(reg) do |answer|
        if answer.query
          answer.query.each_element { |e|
            if e.namespace == 'jabber:iq:register'
              if e.name == 'instructions'
                instructions = e.text.strip
              else
                fields << e.name
              end
            end
          }
        end

        true
      end

      [instructions, fields]
    end

    ##
    # Register a new user account
    # (may be used instead of Client#auth)
    #
    # This method may raise ServerError if the registration was
    # not successful.
    #
    # password:: String
    # fields:: {String=>String} additional registration information
    #
    # XEP-0077 Defines the following fields for registration information:
    # http://www.xmpp.org/extensions/xep-0077.html
    #
    # 'username'    => 'Account name associated with the user'
    # 'nick'        => 'Familiar name of the user'
    # 'password'    => 'Password or secret for the user'
    # 'name'        => 'Full name of the user'
    # 'first'       => 'First name or given name of the user'
    # 'last'        => 'Last name, surname, or family name of the user'
    # 'email'       => 'Email address of the user'
    # 'address'     => 'Street portion of a physical or mailing address'
    # 'city'        => 'Locality portion of a physical or mailing address'
    # 'state'       => 'Region portion of a physical or mailing address'
    # 'zip'         => 'Postal code portion of a physical or mailing address'
    # 'phone'       => 'Telephone number of the user'
    # 'url'         => 'URL to web page describing the user'
    # 'date'        => 'Some date (e.g., birth date, hire date, sign-up date)'
    #
    def register(password, fields={})
      reg = Iq.new_register(jid.node, password)
      reg.to = jid.domain
      fields.each { |name,value|
        reg.query.add(REXML::Element.new(name)).text = value
      }

      send_with_id(reg)
    end

    ##
    # Remove the registration of a user account
    #
    # *WARNING:* this deletes your roster and everything else
    # stored on the server!
    def remove_registration
      reg = Iq.new_register
      reg.to = jid.domain
      reg.query.add(REXML::Element.new('remove'))
      send_with_id(reg)
    end

    ##
    # Change the client's password
    #
    # Threading is suggested, as this code waits
    # for an answer.
    #
    # Raises an exception upon error response (ServerError from
    # Stream#send_with_id).
    # new_password:: [String] New password
    def password=(new_password)
      iq = Iq.new_query(:set, @jid.domain)
      iq.query.add_namespace('jabber:iq:register')
      iq.query.add(REXML::Element.new('username')).text = @jid.node
      iq.query.add(REXML::Element.new('password')).text = new_password

      err = nil
      send_with_id(iq)
    end
  end
end
