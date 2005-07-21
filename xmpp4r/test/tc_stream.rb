#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
include Jabber

module Jabber
  DEBUG = false
end

class StreamTest < Test::Unit::TestCase
  def setup
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    @stream.start(@conn)
  end

  def teardown
    @stream.close
    @server.close
  end

  ##
  # tests that stream really waits the call to process() to dispatch
  # stanzas to filters
  def test_process
    called = false
    @stream.add_xml_callback { called = true }
    assert(!called)
    @server.puts('<stream:stream>')
    @server.flush
    assert(!called)
    @stream.process
    assert(called)
  end

  ##
  # tests that you can select how many messages you want to get with process
  def test_process_multi
    nbcalls = 0
    called = false
    @stream.add_xml_callback { |element|
      nbcalls += 1
      if element.name == "message"
        called = true
      end
    }
    assert(!called)
    @server.puts('<stream:stream/>')
    @server.flush
    assert(!called)
    @stream.process
    assert(!called)
    assert_equal(1, nbcalls)
    for i in 1..10
      @server.puts('<presence/>')
      @server.flush
    end
    @server.puts('<message/>')
    @server.flush
    assert(!called)
    assert_equal(1, nbcalls)
    @stream.process(8)
    assert_equal(9, nbcalls)
    assert(!called)
    @stream.process(2)
    assert_equal(11, nbcalls)
    assert(!called)
    @stream.process(1)
    assert_equal(12, nbcalls)
    assert(called)
  end

  # tests that you can get all waiting messages if you don't use a parameter
  def test_process_multi2
    @called = false
    @nbcalls = 0
    @stream.add_xml_callback { |element|
      @nbcalls += 1
      if element.name == "message"
        @called = true
      end
    }
    assert(!@called)
    @server.puts('<stream:stream>')
    @server.flush
    assert(!@called)
    @stream.process
    assert(!@called)
    assert_equal(1, @nbcalls)
    for i in 1..20
      @server.puts('<iq/>')
      @server.flush
    end
    @server.puts('<message/>')
    @server.flush
    assert(!@called)
    assert_equal(1, @nbcalls)
    @stream.process
    assert_equal(22, @nbcalls)
    assert(@called)
  end
end
