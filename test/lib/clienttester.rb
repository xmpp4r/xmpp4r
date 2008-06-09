# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

$:.unshift '../lib'
require 'xmpp4r'
require 'test/unit'
require 'socket'
require 'xmpp4r/semaphore'

# This is sane for tests:
Thread::abort_on_exception = true

# Turn $VERBOSE off to suppress warnings about redefinition
oldverbose = $VERBOSE
$VERBOSE = false

module Jabber
  ##
  # The ClientTester is a mix-in which provides a setup and teardown
  # method to prepare a Stream object (@client) and the method
  # interfacing as the "server side":
  # * send(xml):: Send a stanza to @client
  #
  # The server side is a stream, too: add your callbacks to @server
  #
  # ClientTester is written to test complex helper classes.
  module ClientTester
    @@SOCKET_PORT = 65223

    def setup
      servlisten = TCPServer.new(@@SOCKET_PORT)
      serverwait = Semaphore.new
      stream = '<stream:stream xmlns:stream="http://etherx.jabber.org/streams">'

      Thread.new do
        Thread.current.abort_on_exception = true
        serversock = servlisten.accept
        servlisten.close
        serversock.sync = true
        @server = Stream.new
        @server.add_xml_callback do |xml|
          if xml.prefix == 'stream' and xml.name == 'stream'
            send(stream)
            true
          else
            false
          end
        end
        @server.start(serversock)

        serverwait.run
      end

      clientsock = TCPSocket.new('localhost', @@SOCKET_PORT)
      clientsock.sync = true
      @client = Stream.new
#=begin
      class << @client
        def jid
          begin
            #raise
          rescue
            puts $!.backtrace.join("\n")
          end
          JID.new('test@test.com/test')
        end
      end
#=end
      @client.start(clientsock)
      @client.send(stream) { |reply| true }

      @state = 0
      @states = []
      @state_wait = Semaphore.new
      @state_wait2 = Semaphore.new
      @server.add_stanza_callback { |stanza|
        if @state < @states.size
          begin
            @states[@state].call(stanza)
          rescue
            puts "Exception in state: #{$!.class}: #{$!}\n#{$!.join("\n")}"
          end
          @state += 1
          @state_wait2.wait
          @state_wait.run
        end

        false
      }

      serverwait.wait
    end

    def teardown
      @client.close
      @server.close
    end

    def send(xml)
      @server.send(xml)
    end

    def state(&block)
      @states << block
    end

    def wait_state
      @state_wait2.run
      @state_wait.wait
    end

    def skip_state
      @state_wait2.run
    end
  end
end

# Restore the old $VERBOSE setting
$VERBOSE = oldverbose
