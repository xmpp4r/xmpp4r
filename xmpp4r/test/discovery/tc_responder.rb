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

  def test_new2
    r = Discovery::Responder.new(@client, 'xmpp4r',
                                 [Discovery::Identity::new('client', 'XMPP4R', 'bot'),
                                  Discovery::Identity::new('pubsub', 'Personal events', 'pep')],
                                 ['ipv6', Discovery::Feature::new('sslc2s')],
                                 [Discovery::Item::new('foo@bar', 'Foo', nil), Discovery::Item::new('bar@baz', 'Bar', 'barbaz')])
    assert_equal('xmpp4r', r.node)
    assert_equal([Discovery::Identity::new('client', 'XMPP4R', 'bot'),
                  Discovery::Identity::new('pubsub', 'Personal events', 'pep')], r.identities)
    assert_equal([Discovery::Feature::new('ipv6'), Discovery::Feature::new('sslc2s')], r.features)
    assert_equal([], r.forms)
    assert_equal([Discovery::Item::new('foo@bar', 'Foo', nil), Discovery::Item::new('bar@baz', 'Bar', 'barbaz')], r.items)
  end

  def test_generate_item
    r = Discovery::Responder.new(@client, nil, [Discovery::Identity::new('client', 'XMPP4R', 'bot')])
    assert_equal(Discovery::Item::new(@client.jid, 'XMPP4R'), r.generate_item)
  end
end
