#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
require 'xmpp4r/bytestreams'
include Jabber

Jabber::debug=true

class StreamThreadedTest < Test::Unit::TestCase
  def setup
    @tmpfile = Tempfile::new("StreamSendTest")
    @tmpfilepath = @tmpfile.path()
    @tmpfile.unlink
    @servlisten = UNIXServer::new(@tmpfilepath)
    thServer = Thread.new { @server = @servlisten.accept }
    @iostream = UNIXSocket::new(@tmpfilepath)
    n = 0
    while not defined? @server and n < 10
      sleep 0.1
      n += 1
    end
    @stream = Stream::new
    @stream.start(@iostream)
  end

  def teardown
    @stream.close
    @server.close
  end

  def test_process
    @server.puts('<stream:stream xmlns="jabber:component:accept">')
    @server.flush

    message = false
    iq = false
    presence = false
    cntr = 0

    @stream.add_message_callback {
      message = true
    }
    @stream.add_iq_callback {
      iq = true
    } 
    @stream.add_presence_callback {
      presence = true
    }

    @server.puts('<message/>')
    @server.flush
    @server.puts('<iq/>')
    @server.flush
    @server.puts('<presence/>')
    @server.flush


    while !(message && iq && presence) && (cntr < 10)
        cntr+=1;
        sleep 0.1
    end 

    assert_equal(true, message)
    assert_equal(true, iq)
    assert_equal(true, presence)

  end

  def test_file
    @server.puts('<stream:stream xmlns="jabber:component:accept">')
    @server.flush

    incoming = false
    cntr = 0

    ft = Jabber::FileTransfer::Helper.new(@stream)
    ft.add_incoming_callback do |iq,file|
        puts file
        incoming = true
    end

    @server.puts("<iq from='test@local' type='set' to='disk' id='1'><si mime-type='application/octet-stream' profile='http://jabber.org/protocol/si/profile/file-transfer' id='11' xmlns='http://jabber.org/protocol/si'><file name='test' size='105'><desc/></file><feature xmlns='http://jabber.org/protocol/feature-neg'><x type='form' xmlns='jabber:x:data'><field type='list-single' var='stream-method'><option><value>http://jabber.org/protocol/bytestreams</value></option><option><value>http://jabber.org/protocol/iqibb</value></option><option><value>http://jabber.org/protocol/ibb</value></option></field></x></feature></si></iq>")
    @server.flush
    
    while !incoming && (cntr < 10)
        cntr+=1;
        sleep 0.1
    end 
 
  end
end
