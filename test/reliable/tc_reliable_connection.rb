#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

# Jabber::debug = true

class ReliableConnectionTest < Test::Unit::TestCase
    
  def test_connection_retry
    @created_sockets = []
    callback_proc = Proc.new do |socket_init_args|
      @created_sockets << socket_init_args[0]
      raise RuntimeError, "Fail to create socket"
    end
    Jabber::Test::ListenerMocker.with_socket_mocked(callback_proc) do
      conn = Jabber::Reliable::Connection.new("listener1@localhost/hi", {
          :servers => ["server 1", "server 2", "server 3", "server 4"], 
          :port => 12345,
          :max_retry => 3, #3 retries = 4 total tries
          :retry_sleep => 0.1})
      assert_raises(RuntimeError) do
        conn.connect
      end
      assert_equal(["server 1", "server 2", "server 3", "server 4"], @created_sockets.sort)
    end
  end
  
end