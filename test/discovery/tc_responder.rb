#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r/discovery/helper/responder'
include Jabber

class Discovery::ResponderTest < Test::Unit::TestCase
  include ClientTester

  def test_new
    r = Discovery::Responder.new(@client)
    assert_nil(r.node)
    assert_equal([], r.identities)
    assert_equal([], r.features)
    assert_equal([], r.forms)
    assert_equal([], r.items)
  end
end
