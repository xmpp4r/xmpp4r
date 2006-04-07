$:.unshift '../lib'
require 'xmpp4r'
require 'test/unit'
require 'tempfile'

module Jabber
  ##
  # The ClientTester is a mix-in which provides a setup and teardown
  # method to prepare a Stream object (@client) and two methods
  # interfacing as the "server side":
  # * send(xml):: Send a stanza to @client
  # * receive:: (Wait and) retrieve a stanza sent by the client (in order)
  #
  # The server side is a stream, too: add your callbacks to @server
  #
  # ClientTester is written to test complex helper classes.
  module ClientTester
    def setup
      tmpfile = Tempfile::new("StreamSendTest")
      @tmpfilepath = tmpfile.path()
      tmpfile.unlink

      servlisten = UNIXServer::new(@tmpfilepath)
      Thread.new {
        serversock = servlisten.accept
        serversock.sync = true
        @server = Stream.new(true)
        @server.add_xml_callback { |xml|
          if xml.prefix == 'stream' and xml.name == 'stream'
            send('<stream:stream>')
            true
          else
            false
          end
        }
        @server.start(serversock)
      }

      clientsock = UNIXSocket::new(@tmpfilepath)
      clientsock.sync = true
      @client = Stream.new(true)
      @client.start(clientsock)

      @client.send('<stream:stream>') { |reply|
        true
      }

      @state = 0
      @states = []
      @server.add_stanza_callback { |stanza|
        if @state < @states.size
          @states[@state].call(stanza)
          @state += 1
        else
          raise "Out of states"
        end
        false
      }
    end

    def teardown
      @client.close
      @server.close
      File::unlink(@tmpfilepath)
    end

    def send(xml)
      @server.send(xml)
    end

    def receive
      @receive_lock.lock

      loop {
        @stanzas_lock.synchronize {
          if @stanzas.size > 0
            @receive_lock.unlock
            return @stanzas.shift
          end
        }

        @receive_lock.lock
        @receive_lock.unlock
      }
    end

    def state(&block)
      @states << block
    end
  end
end
