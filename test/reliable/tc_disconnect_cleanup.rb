#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

# Jabber::debug = true

class ConnectionDisconnectCleanupTest < Test::Unit::TestCase
  class PipeConnection < Jabber::Connection
    attr_accessor :socket_override
    def connect
      begin
        @port = 1024 + rand(32768 - 1024)
        tcpsocket = TCPServer.new("127.0.0.1", @port)
      rescue Errno::EADDRINUSE, Errno::EACCES
        tcpsocket.close rescue nil
        retry
      end
      super("127.0.0.1", @port)
    end
    def accept_features
      #do nothing
    end
    def start
      @socket = self.socket_override
      super
    end
  end
  
  def test_cleanup_when_disconnected_during_keepalive
    rd, wr = IO.pipe
    conn = PipeConnection.new
    
    Thread.new do
      conn.socket_override = rd
      #this will raise exception in keepalive thread, when attempts to send blank space shortly after connect
      conn.instance_eval{ @keepalive_interval = 0.1 }
      conn.connect
    end
    
    sleep(0.2)
    
    assert rd.closed?
    assert !conn.is_connected?
    assert !conn.instance_eval{ @parser_thread }.alive?
    assert !conn.instance_eval{ @keepaliveThread }.alive?    
  end
  
  def test_cleanup_after_stream_close
    rd, wr = IO.pipe
    conn = PipeConnection.new
    
    Thread.new do
      conn.socket_override = rd
      conn.connect
    end
    
    wr.write("<hi/>")    
    wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !conn.is_connected?
    assert !conn.instance_eval{ @parser_thread }.alive?
    assert !conn.instance_eval{ @keepaliveThread }.alive?
  end
  
  def test_cleanup_after_stream_end
    rd, wr = IO.pipe    
    conn = PipeConnection.new
    
    Thread.new do
      conn.socket_override = rd
      conn.connect
    end
    
    wr.write('<stream:stream xmlns:stream="http://etherx.jabber.org/streams">')
    wr.write("</stream:stream>")
    # wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !conn.is_connected?
    assert !conn.instance_eval{ @parser_thread }.alive?
    assert !conn.instance_eval{ @keepaliveThread }.alive?
  end
  
end

class StreamDisconnectCleanupTest < Test::Unit::TestCase
  
  def test_cleanup_when_errors_on_send
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    assert !stream.is_connected?

    stream.start(rd)
    wr.write("<hi/>")
    assert stream.is_connected?
    #should raise error trying to write to stream that can't be written to, and catch should close it.
    assert_raises(IOError){
      stream.send("<hi/>")
    }
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end
  
  def test_cleanup_after_stream_close
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    assert !stream.is_connected?

    stream.start(rd)
    wr.write("<hi/>")
    assert stream.is_connected?

    wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end

  def test_cleanup_after_stream_end
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    assert !stream.is_connected?

    stream.start(rd)
    wr.write('<stream:stream xmlns:stream="http://etherx.jabber.org/streams">')
    wr.write("</stream:stream>")
    assert stream.is_connected?

    # wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end

  def test_cleanup_after_parse_failure
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    assert !stream.is_connected?

    stream.start(rd)
    wr.write('<this is bad xml>>')
    wr.close
    assert stream.is_connected?

    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end
  
end