# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io

# TODO: eval  <body type='terminate' condition=

require 'xmpp4r/client'
require 'xmpp4r/semaphore'
require 'net/http'
require 'uri'
require 'cgi' # for escaping

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

        @no_proxy = []
        @proxy_args = []
      end

      ##
      # Set up proxy from the given url

      # url:: [URI::Generic or String] of the form:
      # when without proxy authentication
      #   http://proxy_host:proxy_port/
      # when with proxy authentication
      #   http://proxy_user:proxy_password@proxy_host:proxy_port/
      def http_proxy_uri=(uri)
        uri = URI.parse(uri) unless uri.respond_to?(:host)
        @proxy_args = [
                       uri.host,
                       uri.port,
                       uri.user,
                       uri.password,
                      ]
      end

      ##
      # Set up proxy from the environment variables
      #
      # Following environment variables are considered
      # HTTP_PROXY, http_proxy
      # NO_PROXY, no_proxy
      # HTTP_PROXY_USER, HTTP_PROXY_PASSWORD
      def http_proxy_env
        @proxy_args = []
        env_proxy = ENV['http_proxy'] || ENV['HTTP_PROXY']
        return if env_proxy.nil? or env_proxy.empty?

        uri = URI.parse env_proxy
        unless uri.user or uri.password then
          uri.user     = CGI.escape (ENV['http_proxy_user'] || ENV['HTTP_PROXY_USER']) rescue nil
          uri.password = CGI.escape (ENV['http_proxy_pass'] || ENV['HTTP_PROXY_PASS']) rescue nil
        end

        self.http_proxy_uri = uri

        @no_proxy = (ENV['NO_PROXY'] || ENV['no_proxy'] || 'localhost, 127.0.0.1').split(/\s*,\s*/)
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
        @pending_rid_lock = Mutex.new
        @pending_rid_cv = [] # [ [rid, cv], [rid, cv], ... ]

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
        res_body = post(req_body, "sid=new rid=#{@http_rid}")
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
        res_body = post(req_body, "terminate sid=#{@http_sid} rid=#{@http_rid}")
        sleep(3)
        Jabber::debuglog("Connection closed")
      end

      private

      ##
      # Receive stanzas ensuring that the 'rid' order is kept
      # result:: [REXML::Element]
      def receive_elements_with_rid(rid, elements)
        @pending_rid_lock.synchronize do
          # Wait until rid == @pending_rid
          if rid > @pending_rid
            cv = ConditionVariable.new
            @pending_rid_cv << [rid, cv]
            @pending_rid_cv.sort!
            while rid > @pending_rid
              cv.wait(@pending_rid_lock)
            end
          end
        end

        elements.each { |e|
          receive(e)
        }

        # Signal waiting elements
        @pending_rid_lock.synchronize do
          @pending_rid = rid + 1 # Ensure @pending_rid is modified atomically
          if @pending_rid_cv.size > 0 && @pending_rid_cv.first.first == @pending_rid
            next_rid, cv = @pending_rid_cv.shift
            cv.signal
          end
        end
      end

      ##
      # Do a POST request
      def post(body, debug_info)
        body = body.to_s
        request = Net::HTTP::Post.new(@uri.path)
        request.content_length = body.size
        request.body = body
        request['Content-Type'] = @http_content_type
        Jabber::debuglog("HTTP REQUEST (#{@pending_requests}/#{@http_requests}) #{debug_info}:\n#{request.body}")

        net_http_args = [@uri.host, @uri.port]
        unless @proxy_args.empty?
          unless no_proxy?(@uri)
            net_http_args.concat @proxy_args
          end
        end

        http = Net::HTTP.new(*net_http_args)
        if @uri.kind_of? URI::HTTPS
          http.use_ssl = true
          @http_ssl_setup and @http_ssl_setup.call(http)
        end
        http.read_timeout = @http_wait * 1.1

        response = http.start { |http|
          http.request(request)
        }
        Jabber::debuglog("HTTP RESPONSE (#{@pending_requests}/#{@http_requests}) #{debug_info}: #{response.class}\n#{response.body}")

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
      # Check whether uri should be accessed without proxy
      def no_proxy?(uri)
        @no_proxy.each do |host_addr|
          return true if uri.host.match(Regexp.quote(host_addr) + '$')
        end
        return false
      end

      ##
      # Prepare data to POST and
      # handle the result
      def post_data(data, restart = false)
        req_body = nil
        current_rid = nil
        debug_info = ''

        begin
          begin
            @lock.synchronize {
              # Do not send unneeded requests
              if data.size < 1 and @pending_requests > 0 and !restart
		@pending_requests += 1 # compensate for decrement in ensure clause
                Jabber::debuglog "post_data: not sending excessive poll"
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
              debug_info = "sid=#{@http_sid} rid=#{current_rid}"

              @pending_requests += 1
              @last_send = Time.now
            }

            res_body = post(req_body, debug_info)

          ensure
            @lock.synchronize {
              @pending_requests -= 1
            }
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
            Jabber::debuglog "Exception caught when parsing HTTP response! (#{debug_info})"
            close
            raise
          end

        rescue StandardError => e
          Jabber::debuglog("POST error (will retry) #{debug_info}: #{e.class}: #{e}, #{e.backtrace}")
          receive_elements_with_rid(current_rid, [])
          # It's not good to resend on *any* exception,
          # but there are too many cases (Timeout, 404, 502)
          # where resending is appropriate
          # TODO: recognize these conditions and act appropriate
          # FIXME: resending the same data with a new rid is wrong.  should resend with the same rid
          send_data(data)
        end
      end

      ##
      # Restart stream after SASL authentication
      def restart
        Jabber::debuglog("Restarting after SASL")
        @stream_mechanisms = []
        @stream_features = {}
        @features_sem = Semaphore.new
        send_data('', true) # restart
      end

      ##
      # Send data,
      # buffered and obeying 'polling' and 'requests' limits
      def send_data(data, restart = false)
        Jabber::debuglog("send_data")

        while true do # exit by return
          @lock.synchronize do
            if @last_send + 0.05 >= Time.now
              Jabber::debuglog("send_data too fast: waiting 0.05sec")
              next
            end

            @send_buffer += data
            limited_by_polling = false
            if @pending_requests + 1 == @http_requests && @send_buffer.size == 0
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
                post_data(data, restart)
              end
              return
            elsif limited_by_requests
              Jabber::debuglog("send_data limited by requests")
              # Do nothing.
              # When a pending request gets an response, it calls send_data('')
              return
            elsif # limited_by_polling && @authenticated
              # Wait until we get some data to send, or @http_polling expires
              Jabber::debuglog("send_data limited by polling: #{@http_polling}")
            else
              Jabber::errorlog("send_data: can't happen: pending_requests=#{@pending_requests} http_requests=#{@http_requests} send_buffer.size=#{@send_buffer.size} limited_by_polling=#{limited_by_polling} limited_by_requests=#{limited_by_requests}")
              return
            end
          end
          sleep(0.1)
        end
      end
    end
  end
end
