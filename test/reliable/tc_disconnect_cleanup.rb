#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

# Jabber::debug = true
# Jabber::warnings = true

class ClientDisconnectCleanupTest < Test::Unit::TestCase
  class ControledClient < Jabber::Client
    attr_accessor :tcpserver, :socket_override
    def connect
      begin
        @port = 1024 + rand(32768 - 1024)
        @tcpserver = TCPServer.new("127.0.0.1", @port)
      rescue Errno::EADDRINUSE, Errno::EACCES
        @tcpserver.close rescue nil
        retry
      end
      super("127.0.0.1", @port)
    end
    def start
      @socket = socket_override
      super
    end
  end

  def test_regular_stream_end
    rd, wr = IO.pipe
    rd.instance_eval do
      def write(*args)
      end
      def flush
      end
    end
    client = ControledClient.new("test@localhost")
    @exceptions_caught = 0
    client.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
    Thread.new do
      client.socket_override = rd
      client.instance_eval{ @keepalive_interval = 0.1 }
      client.connect
      client.auth_nonsasl("password", false)
    end
    sleep(0.1)
    assert client.is_connected?
    
    wr.write('<stream:stream xmlns:stream="http://etherx.jabber.org/streams">')
    wr.write("</stream:stream>")
    sleep(0.2)
    
    assert !client.is_connected?
    assert client.instance_eval{ @parser_thread.nil? || !@parser_thread.alive? }
    assert client.instance_eval{ @keepaliveThread.nil? || !@keepaliveThread.alive? }
    assert @exceptions_caught > 0
  end

  def test_error_on_send
    rd, wr = IO.pipe
    rd.instance_eval do
      def write(*args)
      end
      def flush
      end
    end
    client = ControledClient.new("test@localhost")
    @exceptions_caught = 0
    client.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
    Thread.new do
      client.socket_override = rd
      client.connect
      client.auth_nonsasl("password", false)
    end
    sleep(0.1)
    assert client.is_connected?

    rd.instance_eval do
      def write(*args)
        raise "No writting for you, you disconnect now"
      end
    end
    wr.write(%Q{<stream:stream from='localhost' id="acecf234be084aecdc16509077573c7d7200912f" version='1.0'  xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client"><stream:features><auth xmlns='http://jabber.org/features/iq-auth'/></stream:features> })
    sleep(0.1)
    
    assert !client.is_connected?
    assert client.instance_eval{ @parser_thread.nil? || !@parser_thread.alive? }
    assert client.instance_eval{ @keepaliveThread.nil? || !@keepaliveThread.alive? }   
    assert @exceptions_caught > 0
  end

  def test_client_disconnect
    rd, wr = IO.pipe
    rd.instance_eval do
      def write(*args)
      end
      def flush
      end
    end
    client = ControledClient.new("test@localhost")
    @exceptions_caught = 0
    client.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
    Thread.new do
      client.socket_override = rd
      client.connect
      client.auth_nonsasl("password", false)
    end
    wr.write(%Q{<stream:stream from='localhost' id="acecf234be084aecdc16509077573c7d7200912f" version='1.0'  xmlns:stream="http://etherx.jabber.org/streams" xmlns="jabber:client"><stream:features><auth xmlns='http://jabber.org/features/iq-auth'/></stream:features> })
    sleep(0.1)
    assert client.is_connected?
    assert client.instance_eval{ @parser_thread.alive? }
    assert client.instance_eval{ @keepaliveThread.alive? }

    wr.close
    sleep(0.1)
    
    assert !client.is_connected?
    assert client.instance_eval{ @parser_thread.nil? || !@parser_thread.alive? }
    assert client.instance_eval{ @keepaliveThread.nil? || !@keepaliveThread.alive? }   
    assert @exceptions_caught > 0
  end

end

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
    @exceptions_caught = 0
    conn.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
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
    assert @exceptions_caught > 0
  end
  
  def test_cleanup_after_stream_close
    rd, wr = IO.pipe
    conn = PipeConnection.new
    @exceptions_caught = 0
    conn.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
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
    assert @exceptions_caught > 0
  end
  
  def test_cleanup_after_stream_end
    rd, wr = IO.pipe    
    conn = PipeConnection.new
    @exceptions_caught = 0
    conn.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
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
    assert @exceptions_caught > 0
  end
  
end

class StreamDisconnectCleanupTest < Test::Unit::TestCase
  
  def test_cleanup_when_errors_on_send
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    @exceptions_caught = 0
    stream.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
    assert !stream.is_connected?

    stream.start(rd)
    wr.write("<hi/>")
    assert stream.is_connected?
    #should raise error trying to write to stream that can't be written to, and catch should close it.
    begin
      stream.send("<hi/>")
    rescue
    end
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
    assert @exceptions_caught > 0
  end
  
  def test_cleanup_after_stream_close
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    @exceptions_caught = 0
    stream.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end

    assert !stream.is_connected?

    stream.start(rd)
    wr.write("<hi/>")
    assert stream.is_connected?

    wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
    assert @exceptions_caught > 0
  end

  def test_cleanup_after_stream_end
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    @exceptions_caught = 0
    stream.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
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
    assert @exceptions_caught > 0
  end

  def test_cleanup_after_parse_failure
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    @exceptions_caught = 0
    stream.on_exception do |e, connection, where_failed|
      @exceptions_caught += 1
    end
    
    assert !stream.is_connected?

    stream.start(rd)
    wr.write('<this is bad xml>>')
    wr.close
    assert stream.is_connected?

    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
    assert @exceptions_caught > 0
  end
  
end