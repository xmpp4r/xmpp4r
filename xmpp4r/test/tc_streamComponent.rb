#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/component'
require 'xmpp4r/bytestreams'
require 'xmpp4r'
include Jabber

Thread::abort_on_exception = true

class StreamComponentTest < Test::Unit::TestCase
  @@SOCKET_PORT = 65224

  def setup
    servlisten = TCPServer.new(@@SOCKET_PORT)
    serverwait = Mutex.new
    serverwait.lock
    Thread.new {
      serversock = servlisten.accept
      servlisten.close
      serversock.sync = true
      @server = Stream.new(true)
      @server.add_xml_callback { |xml|
        if xml.prefix == 'stream' and xml.name == 'stream'
          @server.send('<stream:stream xmlns="jabber:component:accept">')
          true
        else
          false
        end
      }
      @server.start(serversock)
      
      serverwait.unlock
    }

    @stream = Component::new('test')
    @stream.connect('localhost', @@SOCKET_PORT)

    serverwait.lock
  end

  def teardown
    @stream.close
    @server.close
  end

  def test_process
    stanzas = 0
    message_lock = Mutex.new
    message_lock.lock
    iq_lock = Mutex.new
    iq_lock.lock
    presence_lock = Mutex.new
    presence_lock.lock

    @stream.add_message_callback { |msg|
      assert_kind_of(Message, msg)
      stanzas += 1
      message_lock.unlock
    }
    @stream.add_iq_callback { |iq|
      assert_kind_of(Iq, iq)
      stanzas += 1
      iq_lock.unlock
    } 
    @stream.add_presence_callback { |pres|
      assert_kind_of(Presence, pres)
      stanzas += 1
      presence_lock.unlock
    }

    @server.send('<message/>')
    @server.send('<iq/>')
    @server.send('<presence/>')

    message_lock.lock
    iq_lock.lock
    presence_lock.lock

    assert_equal(3, stanzas)
  end

  def test_file
    incoming_lock = Mutex.new
    incoming_lock.lock

    ft = Jabber::FileTransfer::Helper.new(@stream)
    ft.add_incoming_callback do |iq,file|
      assert_kind_of(Bytestreams::IqSiFile, file)
      incoming_lock.unlock
    end

    @server.send("
<iq from='test@local' type='set' to='disk' id='1'>
  <si mime-type='application/octet-stream' profile='http://jabber.org/protocol/si/profile/file-transfer' id='11' xmlns='http://jabber.org/protocol/si'>
    <file name='test' size='105' xmlns='http://jabber.org/protocol/si/profile/file-transfer'>
      <desc/>
    </file>
    <feature xmlns='http://jabber.org/protocol/feature-neg'>
      <x type='form' xmlns='jabber:x:data'>
        <field type='list-single' var='stream-method'>
	  <option><value>http://jabber.org/protocol/bytestreams</value></option>
	  <option><value>http://jabber.org/protocol/iqibb</value></option>
	  <option><value>http://jabber.org/protocol/ibb</value></option>
	</field>
      </x>
    </feature>
  </si>
</iq>
")
    incoming_lock.lock
  end

  def test_outgoing
    received_wait = Mutex.new
    received_wait.lock

    @server.add_message_callback { |msg|
      assert_kind_of(Message, msg)
      received_wait.unlock
    }

    @stream.send(Message.new)
    received_wait.lock
  end
end
