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
                                 [Discovery::Identity.new('client', 'XMPP4R', 'bot'),
                                  Discovery::Identity.new('pubsub', 'Personal events', 'pep')],
                                 ['ipv6', Discovery::Feature.new('sslc2s')],
                                 [Discovery::Item.new('foo@bar', 'Foo', nil), Discovery::Item.new('bar@baz', 'Bar', 'barbaz')])
    assert_equal('xmpp4r', r.node)
    assert_equal([Discovery::Identity.new('client', 'XMPP4R', 'bot'),
                  Discovery::Identity.new('pubsub', 'Personal events', 'pep')], r.identities)
    assert_equal([Discovery::Feature.new('ipv6'), Discovery::Feature.new('sslc2s')], r.features)
    assert_equal([], r.forms)
    assert_equal([Discovery::Item.new('foo@bar', 'Foo', nil), Discovery::Item.new('bar@baz', 'Bar', 'barbaz')], r.items)
  end

  def test_generate_item
    r = Discovery::Responder.new(@client, nil, [Discovery::Identity.new('client', 'XMPP4R', 'bot')])
    assert_equal(Discovery::Item.new(@client.jid, 'XMPP4R'), r.generate_item)
  end

  def test_query
    Discovery::Responder.new(@client, nil,
                             [Discovery::Identity.new('client', 'XMPP4R', 'bot')],
                             ['ipv6'],
                             [Discovery::Item.new('foo@bar', 'Foo', nil)])

    iq1 = Iq.new(:get)
    iq1.add(Discovery::IqQueryDiscoInfo.new)
    reply1 = @server.send_with_id(iq1)
    assert_equal(:result, reply1.type)
    assert_kind_of(Discovery::IqQueryDiscoInfo, reply1.query)
    assert_nil(reply1.query.node)
    assert_equal(1, reply1.query.identities.size)
    assert_equal('XMPP4R', reply1.query.identities[0].iname)
    assert_equal(['ipv6'], reply1.query.features)

    iq2 = Iq.new(:get)
    iq2.add(Discovery::IqQueryDiscoItems.new)
    reply2 = @server.send_with_id(iq2)
    assert_equal(:result, reply2.type)
    assert_kind_of(Discovery::IqQueryDiscoItems, reply2.query)
    assert_nil(reply2.query.node)
    assert_equal(1, reply2.query.items.size)
    assert_equal(JID.new('foo@bar'), reply2.query.items[0].jid)
  end

  def test_linked
    class << @client
      remove_method(:jid) # avoids warning
      def jid
        JID.new('foo@bar/baz')
      end
    end
    r1 = Discovery::Responder.new(@client, 'child',
                                   [Discovery::Identity.new('client', 'Child', 'bot')])
    r2 = Discovery::Responder.new(@client, nil,
                                   [], [],
                                   [r1])

    iq = Iq.new(:get)
    iq.add(Discovery::IqQueryDiscoItems.new)
    reply = @server.send_with_id(iq)
    assert_kind_of(Discovery::IqQueryDiscoItems, reply.query)
    assert_nil(reply.query.node)
    assert_equal(1, reply.query.items.size)
    assert_equal(JID.new('foo@bar/baz'), reply.query.items[0].jid)
    assert_equal('Child', reply.query.items[0].iname)
    assert_equal('child', reply.query.items[0].node)
  end
end
