#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

# Jabber::debug = true

class ReliableListenerTest < Test::Unit::TestCase
  
  class TestListener < Jabber::Reliable::Listener
    attr_accessor :received_messages
    
    def on_message(got_message)
      self.received_messages ||= []
      self.received_messages << got_message
    end
    
  end
  
  def test_listener
    listener = TestListener.new("listener1@localhost/hi", "test", {:servers => "127.0.0.1", :presence_message => "hi"})
    Jabber::Test::ListenerMocker.mock_out(listener)
    listener.start
    
    message_to_send = Jabber::Message.new
    message_to_send.to = "listener1@localhost/hi"
    message_to_send.body = "hi"
    
    listener.send_message(message_to_send)
    
    assert_equal(1, listener.received_messages.size)
    
    first_message = listener.received_messages[0]
    assert_equal("hi", first_message.body)
    listener.stop
  end
  
  def test_listener_stop_and_start
    listener = TestListener.new("listener1@localhost/hi", "test", {:servers => "127.0.0.1", :presence_message => "hi"})
    Jabber::Test::ListenerMocker.mock_out(listener)
    listener.start
    
    message_to_send = Jabber::Message.new
    message_to_send.to = "listener1@localhost/hi"
    message_to_send.body = "hi"
    
    listener.send_message(message_to_send)
    
    assert_equal(1, listener.received_messages.size)
    
    first_message = listener.received_messages[0]
    assert_equal("hi", first_message.body)
    listener.stop
    
    assert_raises(ArgumentError){
      listener.send_message(message_to_send)      
    }
    
    listener.start
    listener.send_message(message_to_send)    

    assert_equal(2, listener.received_messages.size)
    listener.stop
  end
  
end