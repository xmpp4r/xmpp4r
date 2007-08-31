#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/stream'
include Jabber


class StreamTest < Test::Unit::TestCase
  def setup
    @tmpfile = Tempfile::new("StreamSendTest")
    @tmpfilepath = @tmpfile.path()
    @tmpfile.unlink
    @servlisten = UNIXServer::new(@tmpfilepath)
    @server = nil
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
end
