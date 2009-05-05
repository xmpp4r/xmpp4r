# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

$:.unshift '../lib'
require 'xmpp4r'
require 'test/unit'
require 'socket'
require 'xmpp4r/semaphore'

# Jabber::debug = true
$ctdebug = false
# $ctdebug = true

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

      @state = 0
      @states = []

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

      @processdone_wait = Semaphore.new
      @nextstate_wait = Semaphore.new
      serverwait.wait
      @server.add_stanza_callback { |stanza|
        # Client prepares everything, then calls wait_state. Problem: because
        # of a race condition, it is possible that we receive the stanza before
        # what to do with it is defined. We busy-wait on @states here.
        n = 0
        while @state >= @states.size and n < 1000
          Thread.pass
          n += 1
        end
        if n == 1000
          puts "Unmanaged stanza in state. Maybe processed by helper?" if $ctdebug
        else
          begin
            puts "Calling #{@states[@state]} for #{stanza.to_s}" if $ctdebug
            @states[@state].call(stanza)
          rescue Exception => e
            puts "Exception in state: #{e.class}: #{e}\n#{e.backtrace.join("\n")}"
          end
          @state += 1
          @nextstate_wait.wait
          @processdone_wait.run
        end

        false
      }
      @client.send(stream) { |reply| true }

    end

    def teardown
      # In some cases, we might lost count of some stanzas
      # (for example, if the handler raises an exception)
      # so we can't block forever.
      n = 0
      while @client.processing > 0 and n < 1000
        Thread::pass
        n += 1
      end
      n = 0
      while @server.processing > 0 and n < 1000
        Thread::pass
        n += 1
      end
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
      @nextstate_wait.run
      @processdone_wait.wait
    end

    def skip_state
      @nextstate_wait.run
    end
  end
end

# Restore the old $VERBOSE setting
$VERBOSE = oldverbose
