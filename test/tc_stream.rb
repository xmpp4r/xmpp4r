#!/usr/bin/ruby

$:.unshift '../lib'
$:.unshift './lib/'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
require 'xmpp4r/semaphore'
require 'clienttester'
include Jabber

# Jabber::debug = true

class StreamTest < Test::Unit::TestCase
  include ClientTester

  def busywait(&block)
    n = 0
    while not block.yield and n < 1000
      Thread::pass
      n += 1
    end
  end

  ##
  # tests that connection really waits the call to process() to dispatch
  # stanzas to filters
  def test_process
    called = false
    @client.add_xml_callback { called = true }
    assert(!called)
    @server.send('<iq/>')
    busywait { called }
    assert(called)
  end

  def test_process20
    done = Semaphore.new
    n = 0
    @client.add_message_callback {
      n += 1
      done.run if n % 20 == 0
    }

    20.times {
      @server.send('<message/>')
    }

    done.wait
    assert_equal(20, n)

    @server.send('<message/>' * 20)

    done.wait
    assert_equal(40, n)
  end

  def test_send
    sem = Semaphore::new
    @server.add_xml_callback { |e|
      @server.send(Iq.new(:result))
      sem.run
    }

    called = 0
    @client.send(Iq.new(:get)) { |reply|
      called += 1
      if reply.kind_of? Iq and reply.type == :result
        true
      else
        false
      end
    }
    sem.wait
    busywait { called }
    assert_equal(1, called)
  end

  def test_send_nested
    finished = Semaphore.new

    id = 0
    @server.add_xml_callback do |e|
      id += 1
      if id == 1
        @server.send(Iq.new(:result).set_id('1').delete_namespace)
      elsif id == 2
        @server.send(Iq.new(:result).set_id('2').delete_namespace)
      elsif id == 3
        @server.send(Iq.new(:result).set_id('3').delete_namespace)
      else
        p e
       end
    end

    called_outer = 0
    called_inner = 0

    @client.send(Iq.new(:get)) do |reply|
      called_outer += 1
      assert_kind_of(Iq, reply)
      assert_equal(:result, reply.type)

      if reply.id == '1'
        @client.send(Iq.new(:set)) do |reply2|
          called_inner += 1
          assert_kind_of(Iq, reply2)
          assert_equal(:result, reply2.type)
          assert_equal('2', reply2.id)

          @client.send(Iq.new(:get))

          true
        end
        false
      elsif reply.id == '3'
        true
      else
        false
      end
    end

    assert_equal(2, called_outer)
    assert_equal(1, called_inner)
  end

  def test_send_in_callback
    finished = Semaphore.new

    @client.add_message_callback {
      @client.send_with_id(Iq.new(:get)) { |reply|
        assert_equal(:result, reply.type)
        finished.run
      }
    }

    @server.add_iq_callback { |iq|
      @server.send(Iq.new(:result).set_id(iq.id))
    }

    @server.send(Message.new)
    finished.wait
  end

  def test_similar_children
    n = 0
    @client.add_message_callback { n += 1 }
    assert_equal(0, n)
    @server.send("<message/>")
    busywait { n == 1 }
    assert_equal(1, n)
    @server.send('<message>')
    assert_equal(1, n)
    @server.send('<message/>')
    assert_equal(1, n)
    @server.send('</message>')
    busywait { n == 2 }
    assert_equal(2, n)
    @server.send("<message><stream:stream><message/></stream:stream>")
    assert_equal(2, n)
    @server.send('</message>')
    busywait { n == 3 }
    assert_equal(3, n)
  end
end
