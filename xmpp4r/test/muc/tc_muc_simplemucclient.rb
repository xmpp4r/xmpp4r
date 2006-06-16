#!/usr/bin/ruby


$:.unshift '../../lib'
require '../lib/clienttester'
require 'xmpp4r/muc'
include Jabber

class SimpleMUCClientTest < Test::Unit::TestCase
  include ClientTester

  def test_new1
    m = MUC::SimpleMUCClient.new(@client)
    assert_equal(nil, m.jid)
    assert_equal(nil, m.my_jid)
    assert_equal({}, m.roster)
    assert(!m.active?)
  end

end
