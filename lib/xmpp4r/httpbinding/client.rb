# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

# TODO: eval  <body type='terminate' condition=

require 'xmpp4r/client'
require 'xmpp4r/semaphore'
require 'net/http'

module Jabber
  module HTTPBinding
    ##
    # This class implements an alternative Client
    # using HTTP Binding (JEP0124).
    #
    # This class is designed to be a drop-in replacement
    # for Jabber::Client, except for the
    # Jabber::HTTP::Client#connect method which takes an URI
    # as argument.
    #
    # HTTP requests are buffered to not exceed the negotiated
    # 'polling' and 'requests' parameters.
    #
    # Stanzas in HTTP resonses may be delayed to arrive in the
    # order defined by 'rid' parameters.
    #
    # =Debugging
    # Turning Jabber::debug to true will make debug output
    # not only spit out stanzas but HTTP request/response
    # bodies, too.
    class Client < Jabber::Client

      # Content-Type to be used for communication
      # (you can set this to "text/html")
      attr_accessor :http_content_type
      # The server should wait this value seconds if
      # there is no stanza to be received
      attr_accessor :http_wait
      # The server may hold this amount of stanzas
      # to reduce number of HTTP requests
      attr_accessor :http_hold
      # Hook to initialize SSL parameters on Net::HTTP
      attr_accessor :http_ssl_setup

      ##
      # Initialize
      # jid:: [JID or String]
      def initialize(jid)
        super

        @lock = Mutex.new
        @pending_requests = 0
        @last_send = Time.at(0)
        @send_buffer = ''

        @http_requests = 1
        @http_wait = 20
        @http_hold = 1
        @http_content_type = 'text/xml; charset=utf-8'
      end

      ##
      # Set up the stream using uri as the HTTP Binding URI
      #
      # You may optionally pass host and port parameters
      # to make use of the JEP0124 'route' feature.
      #
      # uri:: [URI::Generic or String]
      # host:: [String] Optional host to route to
      # port:: [Fixnum] Port for route feature
      def connect(uri, host=nil, port=5222)
        uri = URI::parse(uri) unless uri.kind_of? URI::Generic
        @uri = uri

        @allow_tls = false  # Shall be done at HTTP level
        @stream_mechanisms = []
        @stream_features = {}
        @http_rid = IdGenerator.generate_id.to_i
        @pending_rid = @http_rid
        @pending_rid_lock = Semaphore.new

        req_body = REXML::Element.new('body')
        req_body.attributes['rid'] = @http_rid
        req_body.attributes['content'] = @http_content_type
        req_body.attributes['hold'] = @http_hold.to_s
        req_body.attributes['wait'] = @http_wait.to_s
        req_body.attributes['to'] = @jid.domain
        if host
          req_body.attributes['route'] = "xmpp:#{host}:#{port}"
        end
        req_body.attributes['secure'] = 'true'
        req_body.attributes['xmlns'] = 'http://jabber.org/protocol/httpbind'
        res_body = post(req_body)
        unless res_body.name == 'body'
          raise 'Response body is no <body/> element'
        end

        @streamid = res_body.attributes['authid']
        @status = CONNECTED
        @http_sid = res_body.attributes['sid']
        @http_wait = res_body.attributes['wait'].to_i if res_body.attributes['wait']
        @http_hold = res_body.attributes['hold'].to_i if res_body.attributes['hold']
        @http_inactivity = res_body.attributes['inactivity'].to_i
        @http_polling = res_body.attributes['polling'].to_i
        @http_polling = 5 if @http_polling == 0
        @http_requests = res_body.attributes['requests'].to_i
        @http_requests = 1 if @http_requests == 0

        receive_elements_with_rid(@http_rid, res_body.children)

        @features_sem.run
      end

      ##
      # Ensure that there is one pending request
      #
      # Will be automatically called if you've sent
      # a stanza.
      def ensure_one_pending_request
        return if is_disconnected?

        if @lock.synchronize { @pending_requests } < 1
          send_data('')
        end
      end

      ##
      # Close the session by sending
      # <body type='terminate'/>
      def close
        @status = DISCONNECTED
        req_body = nil
        @lock.synchronize {
          req_body = "<body"
          req_body += " rid='#{@http_rid += 1}'"
          req_body += " sid='#{@http_sid}'"
          req_body += " type='terminate'"
          req_body += " xmlns='http://jabber.org/protocol/httpbind'"
          req_body += ">"
          req_body += "<presence type='unavailable' xmlns='jabber:client'/>"
          req_body += "</body>"
          current_rid = @http_rid
          @pending_requests += 1
          @last_send = Time.now
        }
        res_body = post(req_body)
        sleep(3)
        Jabber::debuglog("Connection closed")
      end

      private

      ##
      # Receive stanzas ensuring that the 'rid' order is kept
      # result:: [REXML::Element]
      def receive_elements_with_rid(rid, elements)
        while rid > @pending_rid
          @pending_rid_lock.wait
        end
        @pending_rid = rid + 1

        elements.each { |e|
          receive(e)
        }

        @pending_rid_lock.run
      end

      ##
      # Do a POST request
      def post(body)
        body = body.to_s
        request = Net::HTTP::Post.new(@uri.path)
        request.content_length = body.size
        request.body = body
        request['Content-Type'] = @http_content_type
        Jabber::debuglog("HTTP REQUEST (#{@pending_requests}/#{@http_requests}):\n#{request.body}")
        http = Net::HTTP.new(@uri.host, @uri.port)
        if @uri.kind_of? URI::HTTPS
          http.use_ssl = true
          @http_ssl_setup and @http_ssl_setup.call(http)
        end
        http.read_timeout = @http_wait * 1.1

        response = http.start { |http|
          http.request(request)
        }
        Jabber::debuglog("HTTP RESPONSE (#{@pending_requests}/#{@http_requests}): #{response.class}\n#{response.body}")

        unless response.kind_of? Net::HTTPSuccess
          # Unfortunately, HTTPResponses aren't exceptions
          # TODO: rescue'ing code should be able to distinguish
          raise Net::HTTPBadResponse, "#{response.class}"
        end

        body = REXML::Document.new(response.body).root
        if body.name != 'body' and body.namespace != 'http://jabber.org/protocol/httpbind'
          raise REXML::ParseException.new('Malformed body')
        end
        body
      end

      ##
      # Prepare data to POST and
      # handle the result
      def post_data(data, restart = false)
        req_body = nil
        current_rid = nil

        begin
          begin
            @lock.synchronize {
              # Do not send unneeded requests
              if data.size < 1 and @pending_requests > 0 and !restart
                return
              end

              req_body = "<body"
              req_body += " rid='#{@http_rid += 1}'"
              req_body += " sid='#{@http_sid}'"
              req_body += " xmlns='http://jabber.org/protocol/httpbind'"
              req_body += " xml:lang='en' xmpp:restart='true' xmlns:xmpp='urn:xmpp:xbosh'" if restart
              req_body += ">"
              req_body += data unless restart
              req_body += "</body>"
              current_rid = @http_rid

              @pending_requests += 1
              # Jabber::debuglog("Before request: pending_requests = #{@pending_requests}")
              # Jabber::debuglog("backtrace #{caller.inspect}")
              @last_send = Time.now
            }

            res_body = post(req_body)

          ensure
            @lock.synchronize {
              @pending_requests -= 1
              if @pending_requests < 0
                Jabber::debuglog("pending_requests got < 0!!! ***********")
              end
            }
            Jabber::debuglog("After response: pending_requests = #{@pending_requests}")
          end

          receive_elements_with_rid(current_rid, res_body.children)
          ensure_one_pending_request if @authenticated

        rescue REXML::ParseException
          if @exception_block
            Thread.new do
              Thread.current.abort_on_exception = true
              close; @exception_block.call(e, self, :parser)
            end
          else
            Jabber::debuglog "Exception caught when parsing HTTP response!"
            close
            raise
          end

        rescue StandardError => e
          Jabber::debuglog("POST error (will retry): #{e.class}: #{e}")
          receive_elements_with_rid(current_rid, [])
          # It's not good to resend on *any* exception,
          # but there are too many cases (Timeout, 404, 502)
          # where resending is appropriate
          # TODO: recognize these conditions and act appropriate
          send_data(data)
        end
      end

      ##
      # Restart stream after SASL authentication
      def restart
        Jabber::debuglog(" ********** Restarting after SASL")
        @stream_mechanisms = []
        @stream_features = {}
        @features_sem = Semaphore.new
        send_data('', true) # restart
        Jabber::debuglog("Semaphore tickets = #{@features_sem.instance_eval { @tickets }}")
      end

      ##
      # Send data,
      # buffered and obeying 'polling' and 'requests' limits
      def send_data(data, restart = false)
        @lock.synchronize do
          Jabber::debuglog("send_data")

          @send_buffer += data
          limited_by_polling = false
          if @pending_requests + 1 == @http_requests
            limited_by_polling = (@last_send + @http_polling >= Time.now)
          end
          limited_by_requests = (@pending_requests + 1 > @http_requests)

          # Can we send?
          if !limited_by_polling and !limited_by_requests or !@authenticated
            Jabber::debuglog("send_data non_limited")
            data = @send_buffer
            @send_buffer = ''

            Thread.new do
              Thread.current.abort_on_exception = true
              sleep(0.05)
              post_data(data, restart)
            end

          elsif !limited_by_requests
            Jabber::debuglog("send_data limited")
            Thread.new do
              Thread.current.abort_on_exception = true
              # Defer until @http_polling has expired
              wait = @last_send + @http_polling - Time.now
              sleep(wait) if wait > 0
              # Ignore locking, it's already threaded ;-)
              send_data('', restart)
            end
          end

        end
      end
    end
  end
end
