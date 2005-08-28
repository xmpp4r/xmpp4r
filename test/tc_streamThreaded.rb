#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r'
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
    while @server.nil? and n < 10
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
end
