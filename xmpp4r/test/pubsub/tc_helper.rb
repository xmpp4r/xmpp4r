#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/pubsub/helper/pubsub'
include Jabber

class PubSub::HelperTest < Test::Unit::TestCase
  include ClientTester

  def test_create
    h = PubSub::Helper.new(@client)
    assert_kind_of(PubSub::Helper, h)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('create', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <create node='#{iq.pubsub.children.first.attributes['node']}'/>
              </pubsub>
            </iq>")
    }
    assert_equal('mynode', h.create('pubsub.example.org', 'mynode'))
  end

  def test_delete
    h = PubSub::Helper.new(@client)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('delete', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.delete('pubsub.example.org', 'mynode')
  end

  def test_publish
    item1 = REXML::Element.new('item1')
    item1.attributes['foo'] = 'bar'
    item1.text = 'foobar'
    item2 = REXML::Element.new('item2')
    item2.attributes['bar'] = 'foo'
    item2.text = 'barfoo'

    h = PubSub::Helper.new(@client)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('publish', iq.pubsub.children[0].name)
      assert_equal(1, iq.pubsub.children[0].children.size)
      assert_equal('item', iq.pubsub.children[0].children[0].name)
      assert_nil(iq.pubsub.children[0].children[0].attributes['id'])
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.publish('pubsub.example.org', 'mynode', {nil=>item1})

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('publish', iq.pubsub.children[0].name)
      assert_equal(2, iq.pubsub.children[0].children.size)
      assert_equal('item', iq.pubsub.children[0].children[0].name)
      assert_equal('1', iq.pubsub.children[0].children[0].attributes['id'])
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      assert_equal('item', iq.pubsub.children[0].children[1].name)
      assert_equal('2', iq.pubsub.children[0].children[1].attributes['id'])
      assert_equal(1, iq.pubsub.children[0].children[1].children.size)
      assert_equal(item2.to_s, iq.pubsub.children[0].children[1].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.publish('pubsub.example.org', 'mynode', {'1'=>item1, '2'=>item2})
  end

  def test_items
    item1 = REXML::Element.new('item1')
    item1.attributes['foo'] = 'bar'
    item1.text = 'foobar'
    item2 = REXML::Element.new('item2')
    item2.attributes['bar'] = 'foo'
    item2.text = 'barfoo'

    h = PubSub::Helper.new(@client)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('items', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <items node='mynode'>
                  <item id='1'>#{item1.to_s}</item>
                  <item id='2'>#{item2.to_s}</item>
                </items>
              </pubsub>
            </iq>")
    }

    items = h.items('pubsub.example.org', 'mynode')
    assert_equal(2, items.size)
    assert_kind_of(REXML::Element, items['1'])
    assert_kind_of(REXML::Element, items['2'])
    assert_equal(item1.to_s, items['1'].to_s)
    assert_equal(item2.to_s, items['2'].to_s)
  end

  def test_affiliations
    h = PubSub::Helper.new(@client)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('affiliations', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
               <affiliations>
                  <affiliation node='node1' affiliation='owner'/>
                  <affiliation node='node2' affiliation='publisher'/>
                  <affiliation node='node5' affiliation='outcast'/>
                  <affiliation node='node6' affiliation='owner'/>
                </affiliations>
              </pubsub>
            </iq>")
    }

    a = h.affiliations('pubsub.example.org')
    assert_kind_of(Hash, a)
    assert_equal(4, a.size)
    assert_equal(:owner, a['node1'])
    assert_equal(:publisher, a['node2'])
    assert_equal(:outcast, a['node5'])
    assert_equal(:owner, a['node6'])
  end

  def test_subscriptions
    h = PubSub::Helper.new(@client)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
                <subscriptions node='princely_musings'>
                  <subscription jid='hamlet@denmark.lit' subscription='subscribed'/>
                  <subscription jid='polonius@denmark.lit' subscription='unconfigured'/>
                  <subscription jid='bernardo@denmark.lit' subscription='subscribed' subid='123-abc'/>
                  <subscription jid='bernardo@denmark.lit' subscription='subscribed' subid='004-yyy'/>
                </subscriptions>
              </pubsub>
            </iq>")
    }

    s = h.subscriptions('pubsub.example.org', 'mynode')
  end
end
