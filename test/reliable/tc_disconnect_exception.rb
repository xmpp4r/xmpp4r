#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

class DisconnectExceptionTest < Test::Unit::TestCase
  class Listener
    def receive(element)
    end
  end
  
  def test_streamparser
    rd, wr = IO.pipe
    listener = Listener.new
    exception_raised = nil
    
    Thread.new do
      begin
        parser = Jabber::StreamParser.new(rd, listener)
        parser.parse
      rescue => e
        exception_raised = e
      end
    end
    
    wr.write("<hi/>")
    wr.close
    sleep(0.1)
    
    assert exception_raised
    assert exception_raised.is_a?(Jabber::ServerDisconnected), "Expected a Jabber::ServerDisconnected but got #{exception_raised}"
    # puts exception_raised.inspect
  end
  
end