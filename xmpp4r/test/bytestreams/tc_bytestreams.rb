#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/bytestreams'
include Jabber

class BytestreamsTest < Test::Unit::TestCase
  include ClientTester

  def create_buffer(size)
    ([nil] * size).collect { rand(256).chr }.join
  end

  def test_ibb_target2initiator
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    buffer = create_buffer(9999)

    Thread.new do
      target.accept
      target.write(buffer)
      Thread.pass
      target.close
    end


    initiator.open

    received = ''
    while buf = initiator.read
      received += buf
    end

    initiator.close

    assert_equal(buffer, received)
  end

  def test_ibb_initiator2target
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    buffer = create_buffer(9999)

    Thread.new do
      Thread.pass
      initiator.open
      initiator.write(buffer)
      Thread.pass
      initiator.close
    end


    target.accept

    received = ''
    while buf = target.read
      received += buf
    end

    target.close

    assert_equal(buffer, received)
  end
  
  def test_ibb_pingpong
    target = Bytestreams::IBBTarget.new(@server, '1', nil, '1@a.com/1')
    initiator = Bytestreams::IBBInitiator.new(@client, '1', nil, '1@a.com/1')

    Thread.new do
      target.accept

      while buf = target.read
        target.write(buf)
        target.flush
      end

      target.close
    end


    initiator.open

    10.times do
      buf = create_buffer(9999)
      initiator.write(buf)
      initiator.flush

      bufr = ''
      begin
        bufr += initiator.read
      end while bufr.size < buf.size
      assert_equal(buf, bufr)
    end

    initiator.close
  end
end
