#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
include Jabber

module Jabber
  DEBUG = false
end

class StreamThreadedTest < Test::Unit::TestCase
  def setup
    @conn, @server = IO.pipe
    @stream = Stream::new
    @stream.start(@conn)
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
end
