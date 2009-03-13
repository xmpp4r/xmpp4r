#!/usr/bin/ruby

$:.unshift "#{File.dirname(__FILE__)}/../../lib"

require 'test/unit'
require 'xmpp4r'

class DisconnectCleanupTest < Test::Unit::TestCase
  
  # Jabber::debug = true
  
  def test_cleanup_after_stream_close
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    stream.start(rd)
    wr.write("<hi/>")
    wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end

  def test_cleanup_after_stream_end
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    stream.start(rd)
    wr.write('<stream:stream xmlns:stream="http://etherx.jabber.org/streams">')
    wr.write("</stream:stream>")
    wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end

  def test_cleanup_after_parse_failure
    rd, wr = IO.pipe
    
    stream = Jabber::Stream.new
    stream.start(rd)
    wr.write('<this is bad xml>>')
    wr.close
    sleep(0.1)
    
    assert rd.closed?
    assert !stream.is_connected?
    assert !stream.instance_eval{ @parser_thread }.alive?
  end
  
end