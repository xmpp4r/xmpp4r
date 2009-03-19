#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/rpc/helper/client'
require 'xmpp4r/rpc/helper/server'
include Jabber

class RPC::HelperTest < Test::Unit::TestCase
  include ClientTester

  def give_client_jid!
    class << @client
      remove_method(:jid) # avoids warning
      def jid; Jabber::JID.new('client@test.com/clienttester'); end
    end
  end

  def test_create
    give_client_jid!

    cl = RPC::Client.new(@client, 'a@b/c')
    assert_kind_of(RPC::Client, cl)
    sv = RPC::Server.new(@server)
    assert_kind_of(RPC::Server, sv)
  end

  def echo(msg = nil)
    msg
  end

  def test_simple
    give_client_jid!

    sv = RPC::Server.new(@server)
    sv.add_handler("echo", &method(:echo))

    cl = RPC::Client.new(@client, 'a@b/c')
    assert_nothing_raised do
      assert_equal('Test string', cl.call("echo", 'Test string'))
    end

    # exception during serialisation bug identified on xmpp4r-devel
    # https://mail.gna.org/public/xmpp4r-devel/2008-05/msg00010.html
    assert_raise XMLRPC::FaultException do
      cl.call("echo")
    end
  end

  def test_introspection
    give_client_jid!

    sv = RPC::Server.new(@server)
    sv.add_introspection

    cl = RPC::Client.new(@client, 'a@b/c')
    cl_methods = cl.call("system.listMethods")
    assert(cl_methods.size > 0)
    cl_methods.each { |method|
      assert_kind_of(String, method)
      assert(method =~ /^system\./)
    }
  end

  def test_multicall
    give_client_jid!

    sv = RPC::Server.new(@server)
    sv.add_multicall
    sv.add_handler("reverse") do |s| s.reverse end
    sv.add_handler("upcase") do |s| s.upcase end

    cl = RPC::Client.new(@client, 'a@b/c')
    assert_equal(['tseT', 'TEST'], cl.multicall(['reverse', 'Test'], ['upcase', 'Test']))
  end

  def test_10calls
    give_client_jid!

    sv = RPC::Server.new(@server)
    sv.add_handler("add") do |a,b| a+b end

    cl = RPC::Client.new(@client, 'a@b/c')
    correct = true
    10.times {
      a, b = rand(1000), rand(1000)
      correct &&= (cl.call('add', a, b) == a + b)
    }

    assert(correct)
  end
end
