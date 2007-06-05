#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
include Jabber

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

  ##
  # tests that connection really waits the call to process() to dispatch
  # stanzas to filters
  def test_process
    called = false
    @stream.add_xml_callback { called = true }
    assert(!called)
    @server.puts('<stream:stream>')
    @server.flush
    assert(called)
  end

  def test_process100
    @server.puts('<stream:stream>')
    @server.flush

    done = Mutex.new
    done.lock
    n = 0
    @stream.add_message_callback {
      n += 1
      done.unlock if n % 100 == 0
    }

    100.times {
      @server.puts('<message/>')
      @server.flush
    }

    done.lock
    assert_equal(100, n)

    @server.puts('<message/>' * 100)
    @server.flush

    done.lock
    assert_equal(200, n)
  end

  def test_send
    @server.puts('<stream:stream>')
    @server.flush

    Thread.new {
      assert_equal(Iq.new(:get).delete_namespace.to_s, @server.gets('>'))
      @stream.receive(Iq.new(:result))
    }

    called = 0
    @stream.send(Iq.new(:get)) { |reply|
      called += 1
      if reply.kind_of? Iq and reply.type == :result
        true
      else
        false
      end
    }

    assert_equal(1, called)
  end

  def test_send_nested
    @server.puts('<stream:stream>')
    @server.flush
    finished = Mutex.new
    finished.lock

    Thread.new {
      assert_equal(Iq.new(:get).delete_namespace.to_s, @server.gets('>'))
      @server.puts(Iq.new(:result).set_id('1').delete_namespace.to_s)
      @server.flush
      assert_equal(Iq.new(:set).delete_namespace.to_s, @server.gets('>'))
      @server.puts(Iq.new(:result).set_id('2').delete_namespace.to_s)
      @server.flush
      assert_equal(Iq.new(:get).delete_namespace.to_s, @server.gets('>'))
      @server.puts(Iq.new(:result).set_id('3').delete_namespace.to_s)
      @server.flush

      finished.unlock
    }

    called_outer = 0
    called_inner = 0

    @stream.send(Iq.new(:get)) { |reply|
      called_outer += 1
      assert_kind_of(Iq, reply)
      assert_equal(:result, reply.type)
      
      if reply.id == '1'
        @stream.send(Iq.new(:set)) { |reply|
          called_inner += 1
          assert_kind_of(Iq, reply)
          assert_equal(:result, reply.type)
          assert_equal('2', reply.id)

          @stream.send(Iq.new(:get))

          true
        }
        false
      elsif reply.id == '3'
        true
      else
        false
      end
    }

    assert_equal(2, called_outer)
    assert_equal(1, called_inner)

    finished.lock
  end

  def test_send_in_callback
    @server.puts('<stream:stream>')
    @server.flush
    finished = Mutex.new
    finished.lock

    @stream.add_message_callback {
      @stream.send_with_id(Iq.new(:get)) { |reply|
        assert_equal(:result, reply.type)
      }
    }

    Thread.new {
      @server.gets('>')
      @server.puts(Iq.new(:result))
      finished.unlock
    }

    @server.puts(Message.new)
    finished.lock
  end

  def test_bidi
    @server.puts('<stream:stream>')
    @server.flush
    finished = Mutex.new
    finished.lock
    ok = true
    n = 100

    Thread.new {
      n.times { |i|
        ok &&= (Iq.new(:get).set_id(i).delete_namespace.to_s == @server.gets('>'))
        @server.puts(Iq.new(:result).set_id(i).to_s)
        @server.flush
      }

      finished.unlock
    }

    n.times { |i|
      @stream.send(Iq.new(:get).set_id(i)) { |reply|
        ok &&= reply.kind_of? Iq
        ok &&= (:result == reply.type)
        ok &&= (i.to_s == reply.id)
        true
      }
    }

    finished.lock
    assert(ok)
  end
end
