#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/rexmladdons'
require 'xmpp4r'
include Jabber

class ConnectionErrorTest < Test::Unit::TestCase
  def test_connectionError
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    @stream.start(@conn)
    error = false
    @stream.on_exception { error = true }
    assert(!error)
    @server.puts('<stream:stream>')
    @server.flush
    assert(!error)
    @server.puts('</blop>')
    sleep 0.1
    assert(error)
    @server.close
    @stream.close
  end

  def test_connectionBool
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    assert(!@stream.is_connected?)
    assert(@stream.is_disconnected?)
    @stream.start(@conn)
    assert(@stream.is_connected?)
    assert(!@stream.is_disconnected?)
    @stream.close
    assert(!@stream.is_connected?)
    assert(@stream.is_disconnected?)
    @server.close
  end

  def test_connectionError2
    @conn, @server = IO.pipe
    @stream = Stream::new(false)
    @stream.start(@conn)
    error = false
    @stream.on_exception { error = true }
    @server.puts('<stream:stream>')
    assert(!error)
    @server.puts('</blop>')
    sleep 0.1
    assert(error)
    @server.close
    @stream.close
  end
end
