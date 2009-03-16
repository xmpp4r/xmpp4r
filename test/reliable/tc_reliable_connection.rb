#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

# Jabber::debug = true

class ReliableConnectionTest < Test::Unit::TestCase
  
  def test_streamparser
    begin
      @port = 1024 + rand(32768 - 1024)
      # @tcpserver = TCPServer.new("127.0.0.1", @port)
    rescue Errno::EADDRINUSE, Errno::EACCES
      # @tcpserver.close rescue nil
      retry
    end
    
    rd, wr = IO.pipe
    
    conn = Jabber::Reliable::Connection.new("listener1@localhost/hi", {
        :servers => ["127.0.0.1", "127.1.1.10"], :port => @port})
    conn.instance_eval{ @socket_override = rd }
    conn.instance_eval do
      class << self
        def start
          @socket = @socket_override
          super
        end
      end
    end
    th = Thread.new do
      conn.connect
    end
    # sleep(0.1)
    
    # rd.instance_eval do
    #   def write(*args)
    #   end
    #   def flush
    #   end
    # end    
    
    # th.join
    # Thread.stop
    #TODO: actually test something here...
    
    th.kill
  end
  
end