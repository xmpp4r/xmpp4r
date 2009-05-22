#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/pubsub/helper/servicehelper'
include Jabber

# Jabber.debug = true

class PubSub::ServiceHelperTest < Test::Unit::TestCase
  include ClientTester

  ##
  # subscribe_to
  # examples 30 and 31 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-subscribe
  def test_subscribe
    pubsub = 'pubsub.example.org'
    h = PubSub::ServiceHelper.new(@client,pubsub)
    assert_kind_of(Jabber::PubSub::ServiceHelper,h)
    state { |iq|
      assert_kind_of(Jabber::Iq,iq)
      assert_equal(:set,iq.type)
      assert_equal(pubsub, iq.to.to_s)
      assert_equal(@client.jid, iq.from)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscribe',iq.pubsub.children.first.name)
      assert_equal('princely_musings',iq.pubsub.children.first.attributes['node'])
      assert_equal(@client.jid.strip.to_s,iq.pubsub.children.first.attributes['jid'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
            <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <subscription node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from.strip}'
                    subid='ba49252aaa4f5d320c24d3766f0bdcade78c78d3'
                    subscription='subscribed'/>
           </pubsub>
           </iq>")
    }
    subscription = h.subscribe_to('princely_musings')
    assert_kind_of(Jabber::PubSub::Subscription,subscription)
    assert_equal(@client.jid.strip,subscription.jid)
    assert_equal('princely_musings',subscription.node)
    assert_equal('ba49252aaa4f5d320c24d3766f0bdcade78c78d3',subscription.subid)
    assert_equal(:subscribed,subscription.subscription)
    wait_state
  end

  ##
  # subscribe error condition
  # example 44 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-subscribe-configure
  def test_subscribe_configuration_required
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(PubSub::ServiceHelper,h)
    state { |iq|
      assert_kind_of(Jabber::Iq,iq)
      assert_equal(:set,iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscribe',iq.pubsub.children.first.name)
      assert_equal('princely_musings',iq.pubsub.children.first.attributes['node'])
      assert_equal(@client.jid.strip.to_s,iq.pubsub.children.first.attributes['jid'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
		    <pubsub xmlns='http://jabber.org/protocol/pubsub'>
		        <subscription node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from.strip}'
		        subid='ba49252aaa4f5d320c24d3766f0bdcade78c78d3'
		        subscription='unconfigured'/>
			<subscribe-options>
			  <required/>
			</subscribe-options>
	 	   </pubsub>
	  </iq>")
    }
    subscription = h.subscribe_to('princely_musings')
    assert_kind_of(Jabber::PubSub::Subscription,subscription)
    assert_equal(@client.jid.strip,subscription.jid)
    assert_equal('princely_musings',subscription.node)
    assert_equal('ba49252aaa4f5d320c24d3766f0bdcade78c78d3',subscription.subid)
    assert_equal(:unconfigured,subscription.subscription)
    wait_state
  end

  ##
  # subscribe error condition
  # example 43 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-subscribe-approval
  def test_subscribe_approval_required
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(PubSub::ServiceHelper,h)
    state { |iq|
      assert_kind_of(Jabber::Iq,iq)
      assert_equal(:set,iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscribe',iq.pubsub.children.first.name)
      assert_equal('princely_musings',iq.pubsub.children.first.attributes['node'])
      assert_equal(@client.jid.strip.to_s,iq.pubsub.children.first.attributes['jid'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
		          <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <subscription node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from.strip}'
				          subid='ba49252aaa4f5d320c24d3766f0bdcade78c78d3'
                  subscription='pending'/>

              </pubsub>
            </iq>")
    }
    subscription = h.subscribe_to('princely_musings')
    assert_kind_of(Jabber::PubSub::Subscription,subscription)
    assert_equal(@client.jid.strip,subscription.jid)
    assert_equal('princely_musings',subscription.node)
    assert_equal('ba49252aaa4f5d320c24d3766f0bdcade78c78d3',subscription.subid)
    assert_equal(:pending,subscription.subscription)
    assert_equal(true,subscription.need_approval?)
    wait_state
  end

  ##
  # unsubscribe from
  # examples 48 and 49 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-unsubscribe-request
  def test_unsubscribe
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(PubSub::ServiceHelper,h)
    state { |iq|
      assert_kind_of(Jabber::Iq,iq)
      assert_equal(:set,iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('unsubscribe',iq.pubsub.children.first.name)
      assert_equal('princely_musings',iq.pubsub.children.first.attributes['node'])
      assert_equal(@client.jid.strip.to_s,iq.pubsub.children.first.attributes['jid'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    unsubscribe = h.unsubscribe_from('princely_musings')
    assert_equal(true, unsubscribe)
    wait_state
  end

  ##
  # get subscription options
  # examples 56 and 57 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-configure-request
  def test_get_subscription_options
    pubsub = Jabber::JID.new('pubsub.example.org')
    node = 'princely_musings'
    jid = Jabber::JID.new('test@test.com/test')
    h = PubSub::ServiceHelper.new(@client, pubsub)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(pubsub, iq.to)
      assert_kind_of(Jabber::PubSub::SubscriptionConfig, iq.pubsub.first_element('options'))
      assert_equal(node, iq.pubsub.first_element('options').node)
      assert_equal(jid.strip, iq.pubsub.first_element('options').jid)

      send( "<iq type='result'
        from='#{iq.to}'
        to='#{iq.from}'
        id='#{iq.id}'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
          <options node='#{iq.pubsub.first_element('options').node}' jid='#{iq.pubsub.first_element('options').jid}'>
            <x xmlns='jabber:x:data' type='form'>
            <field var='FORM_TYPE' type='hidden'>
              <value>http://jabber.org/protocol/pubsub#subscribe_options</value>
            </field>
            <field var='pubsub#deliver' type='boolean'
              label='Enable delivery?'>
              <value>1</value>
            </field>
            </x>
          </options>
        </pubsub>
        </iq>")
    }

    options = h.get_options_from(node, jid)
    assert_kind_of(Jabber::PubSub::SubscriptionConfig, options)
    assert_equal({'pubsub#deliver'=>'1'}, options.options)
    wait_state
  end

  ##
  # set subscription options
  # examples 65 and 66 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-configure-submit
  def test_set_subscription_options
    pubsub = Jabber::JID.new('pubsub.example.org')
    node = 'princely_musings'
    jid = Jabber::JID.new('test@test.com/test')
    options = {'pubsub#deliver' => '0'}
    h = PubSub::ServiceHelper.new(@client, pubsub)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(pubsub, iq.to)
      assert_kind_of(Jabber::PubSub::SubscriptionConfig, iq.pubsub.first_element('options'))
      assert_equal(node, iq.pubsub.first_element('options').node)
      assert_equal(jid.strip, iq.pubsub.first_element('options').jid)

      send( "<iq type='result'
        from='#{iq.to}'
        to='#{iq.from}'
        id='#{iq.id}'/>")
    }

    assert_nothing_raised do
      assert_equal(true, h.set_options_for(node, jid, options) )
    end
    wait_state
  end

  ##
  # create node with default configuration
  # example 119 and 121 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-create-default
  def test_create
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(PubSub::ServiceHelper, h)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(2, iq.pubsub.children.size)
      assert_equal('create', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      assert_equal('configure', iq.pubsub.children[1].name)
      assert_equal({}, iq.pubsub.children[1].attributes)
      assert_equal([], iq.pubsub.children[1].children)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    assert_equal('mynode', h.create_node('mynode'))
    wait_state
  end

  ##
  # create node with configuration
  # example 123 and 124 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-create-and-configure
  def test_create_configure
    node = 'mynode'
    options = {'pubsub#access_model'=>'open'}
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(2, iq.pubsub.children.size)
      assert_equal('create', iq.pubsub.children.first.name)
      assert_equal(node, iq.pubsub.children.first.attributes['node'])
      assert_kind_of(Jabber::PubSub::NodeConfig, iq.pubsub.children[1])
      assert_equal(options, iq.pubsub.children[1].options)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }

    assert_nothing_raised do
      assert_equal(node, h.create_node(node, Jabber::PubSub::NodeConfig.new(node, options)))
    end

    wait_state
  end

  ##
  # create node a collection node
  # example 203 and 204 from
  # http://www.xmpp.org/extensions/xep-0060.html#collections-createnode
  def test_create_collection
    node = 'mynode'
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    required_options = {'pubsub#node_type' => 'collection'}
    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(2, iq.pubsub.children.size)
      assert_equal('create', iq.pubsub.children.first.name)
      assert_equal(node, iq.pubsub.children.first.attributes['node'])
      assert_kind_of(Jabber::PubSub::NodeConfig, iq.pubsub.children[1])
      assert_equal(required_options, iq.pubsub.children[1].options)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    assert_equal('mynode', h.create_collection_node('mynode'))
    wait_state
  end

  ##
  # delete node
  # example 144 and 145 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-delete-request
  def test_delete
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('delete', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.delete_node('mynode')
    wait_state
  end

  ##
  # publish to a node
  # example 88 and 89 from
  # http://www.xmpp.org/extensions/xep-0060.html#publisher-publish
  def test_publish
    node = 'mynode'
    item1 = Jabber::PubSub::Item.new
    item1.text = 'foobar'
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('publish', iq.pubsub.children[0].name)
      assert_equal(node, iq.pubsub.children[0].attributes['node'])
      assert_equal(1, iq.pubsub.children[0].children.size)
      assert_equal('item', iq.pubsub.children[0].children[0].name)
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.children[0].to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    assert_nothing_raised { h.publish_item_to(node, item1) }
    wait_state
  end

  ##
  # publish item with id
  # example 88 and 89 from
  # http://www.xmpp.org/extensions/xep-0060.html#publisher-publish
  def test_publish_pubsub_item_with_id
    item1 = Jabber::PubSub::Item.new
    item1.text = 'foobar'
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('publish', iq.pubsub.children[0].name)
      assert_equal(1, iq.pubsub.children[0].children.size)
      assert_equal('item', iq.pubsub.children[0].children[0].name)
      assert_equal('blubb', iq.pubsub.children[0].children[0].attributes['id'] )
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.children[0].to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    assert_nothing_raised { h.publish_item_with_id_to('mynode', item1,"blubb") }
    wait_state
  end

  ##
  # publish item and trap client-side error
  # examples 88 from
  # http://www.xmpp.org/extensions/xep-0060.html#publisher-publish
  def test_publish_pubsub_item_with_id_and_produce_a_local_error
    item1 = 'foobarbaz'
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    assert_raise RuntimeError do h.publish_item_with_id_to('mynode', item1,"blubb") end
  end

  ##
  # publish item and trap server-side error
  # examples 88 from
  # http://www.xmpp.org/extensions/xep-0060.html#publisher-publish
  # and 93 from
  # http://www.xmpp.org/extensions/xep-0060.html#publisher-publish-error-forbidden
  def test_publish_pubsub_item_with_id_and_produce_an_error
    item1 = Jabber::PubSub::Item.new
    item1.text = "foobarbaz"
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.children.size)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('publish', iq.pubsub.children[0].name)
      assert_equal(1, iq.pubsub.children[0].children.size)
      assert_equal('item', iq.pubsub.children[0].children[0].name)
      assert_equal('blubb', iq.pubsub.children[0].children[0].attributes['id'] )
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.children[0].to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='error' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>
      <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <publish node='#{iq.pubsub.children[0].attributes['node']}'>
          <item id='#{iq.pubsub.children[0].children[0].attributes['id']}'/>
       </publish>
      </pubsub>
      <error type='auth'>
        <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
      </error>")
    }
    assert_raise Jabber::ServerError do h.publish_item_with_id_to('mynode', item1,"blubb") end
    wait_state
  end

  ##
  # retrieve all items
  # examples 70 and 71 from
  # http://www.xmpp.org/extensions/xep-0060.html#subscriber-retrieve-returnall
  def test_items
    item1 = Jabber::PubSub::Item.new("1")
    item1.text = 'foobar'
    item2 = Jabber::PubSub::Item.new("2")
    item2.text = 'barfoo'

    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('items', iq.pubsub.children.first.name)
      assert_equal('mynode', iq.pubsub.children.first.attributes['node'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <items node='mynode'>
                  #{item1.to_s}
                  #{item2.to_s}
                </items>
              </pubsub>
            </iq>")
    }

    items = h.get_items_from('mynode')
    assert_equal(2, items.size)
    assert_kind_of(REXML::Text, items['1'])
    assert_kind_of(REXML::Text, items['2'])
    assert_equal(item1.children.join, items['1'].to_s)
    assert_equal(item2.children.join, items['2'].to_s)
    wait_state
  end

  ##
  # retrieve some items
  # example 76 from
  # http://xmpp.org/extensions/xep-0060.html#subscriber-retrieve-requestsome
  def test_items_with_max_items
    node_name = "mynode"
    max_items = 2
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('items', iq.pubsub.children.first.name)
      assert_equal(node_name, iq.pubsub.children.first.attributes['node'])
      assert_equal(max_items.to_s, iq.pubsub.children.first.attributes['max_items'])
      # response doesn't matter; was previously tested, so send a simple result
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}' />")
    }

    h.get_items_from(node_name, max_items)
    wait_state
  end

  ##
  # get affiliation
  # example 184 and 185 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-affiliations-retrieve-success1
  def test_affiliations
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

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

    a = h.get_affiliations
    assert_kind_of(Hash, a)
    assert_equal(4, a.size)
    assert_equal(:owner, a['node1'])
    assert_equal(:publisher, a['node2'])
    assert_equal(:outcast, a['node5'])
    assert_equal(:owner, a['node6'])
    wait_state
  end

  # http://xmpp.org/extensions/xep-0060.html#owner-affiliations-modify
  def test_set_affiliations
    h = PubSub::ServiceHelper.new(@client,'pubsub.shakespeare.lit')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:set, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('affiliations', iq.pubsub.children[0].name)
      assert_equal('affiliation', iq.pubsub.children[0].children[0].name)
      assert_equal('bard@shakespeare.lit', iq.pubsub.children[0].children[0].attributes['jid'])
      assert_equal('publisher', iq.pubsub.children[0].children[0].attributes['affiliation'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }

    a = h.set_affiliations('princely_musings', 'bard@shakespeare.lit', :publisher)
    wait_state
  end

  ##
  # get_subscriptions_from
  # example 171 and 172 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-subscriptions-retrieve-request
  def test_subscriptions
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
                <subscriptions node='node1'>
                  <subscription jid='hamlet@denmark.lit' subscription='subscribed'/>
                  <subscription jid='polonius@denmark.lit' subscription='unconfigured'/>
                  <subscription jid='bernardo@denmark.lit' subscription='subscribed' subid='123-abc'/>
                  <subscription jid='bernardo@denmark.lit' subscription='subscribed' subid='004-yyy'/>
                </subscriptions>
              </pubsub>
            </iq>")
    }

    s = h.get_subscriptions_from('node1')
    assert_kind_of(Array,s)
    assert_equal(4,s.size)
    assert_kind_of(Jabber::PubSub::Subscription,s[0])
    assert_kind_of(Jabber::PubSub::Subscription,s[1])
    assert_kind_of(Jabber::PubSub::Subscription,s[2])
    assert_kind_of(Jabber::PubSub::Subscription,s[3])
    assert_equal(:subscribed,s[0].state)
    assert_equal(:unconfigured,s[1].state)
    assert_equal(JID.new("hamlet@denmark.lit"),s[0].jid)
    assert_equal("123-abc",s[2].subid)
    wait_state
  end

  ##
  # get_subscribers
  # example 171 and 172 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-subscriptions-retrieve
  def test_subscribers
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub'>
        <subscriptions node='princely_musings'>
        <subscription jid='peter@denmark.lit' subscription='subscribed'/>
        <subscription jid='frank@denmark.lit' subscription='subscribed'/>
        <subscription jid='albrecht@denmark.lit' subscription='unconfigured'/>
        <subscription jid='hugo@denmark.lit' subscription='pending'/>
        </subscriptions>
        </pubsub>
      </iq>")
    }

    s = h.get_subscribers_from('princely_musings')
    assert_equal(4,s.size)
    assert_kind_of(Jabber::JID,s[0])
    assert_kind_of(Jabber::JID,s[1])
    assert_kind_of(Jabber::JID,s[2])
    assert_kind_of(Jabber::JID,s[3])
    wait_state
  end

  ##
  # get_all_subscriptions
  def test_get_all_subscriptions
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
            <pubsub xmlns='http://jabber.org/protocol/pubsub'>
              <subscriptions>
                <subscription node='node1' jid='francisco@denmark.lit' subscription='subscribed'/>
                <subscription node='node2' jid='francisco@denmark.lit' subscription='subscribed'/>
                <subscription node='node5' jid='francisco@denmark.lit' subscription='unconfigured'/>
                <subscription node='node6' jid='francisco@denmark.lit' subscription='pending'/>
                </subscriptions>
              </pubsub>
            </iq>")
    }

    s = h.get_subscriptions_from_all_nodes
    assert_kind_of(Array,s)
    assert_equal(4,s.size)
    assert_kind_of(Jabber::PubSub::Subscription,s[0])
    assert_kind_of(Jabber::PubSub::Subscription,s[1])
    assert_kind_of(Jabber::PubSub::Subscription,s[2])
    assert_kind_of(Jabber::PubSub::Subscription,s[3])
    assert_equal(:subscribed,s[0].state)
    assert_equal(:unconfigured,s[2].state)
    assert_equal(:pending,s[3].state)
    assert_equal(JID.new("francisco@denmark.lit"),s[0].jid)
    assert_equal("node1",s[0].node)

    wait_state
  end

  ##
  # get all subscriptions with no subscriptions
  def test_get_all_subscriptions_with_no_subscriptions
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscriptions', iq.pubsub.children.first.name)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
              <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <subscriptions />
              </pubsub>
            </iq>")
    }

    s = h.get_subscriptions_from_all_nodes
    assert_kind_of(Array,s)
    assert_equal(0,s.size)
    wait_state
  end

  ##
  # get configuration for a node
  # example 125 and 126 from
  # http://www.xmpp.org/extensions/xep-0060.html#owner-configure-request
  def test_get_node_config
    pubsub = 'pubsub.example.org'
    h = PubSub::ServiceHelper.new(@client, pubsub)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:get, iq.type)
      assert_equal(pubsub, iq.to.to_s)
      assert_kind_of(Jabber::PubSub::OwnerNodeConfig, iq.pubsub.first_element('configure'))

      send( "<iq type='result'
        from='#{iq.to}'
        to='#{iq.from}'
        id='#{iq.id}'>
        <pubsub xmlns='http://jabber.org/protocol/pubsub#owner'>
          <configure node='princely_musings'>
            <x xmlns='jabber:x:data' type='form'>
              <field var='FORM_TYPE' type='hidden'>
                <value>http://jabber.org/protocol/pubsub#node_config</value>
              </field>
              <field var='pubsub#title' type='text-single'
               label='A friendly name for the node'/>
            </x>
          </configure>
        </pubsub>
        </iq>")
    }

    config = h.get_config_from('princelymusings')
    assert_kind_of(Jabber::PubSub::OwnerNodeConfig, config)
    wait_state
  end

  ##
  # owner set configuration for a node
  # example 133
  # http://xmpp.org/extensions/xep-0060.html#owner-configure
  def test_set_node_config
    node = 'princely_musings'
    pubsub = 'pubsub.shakespeare.lit'
    h = PubSub::ServiceHelper.new(@client,pubsub)
    
    state { |iq|
      assert_kind_of(Jabber::Iq,iq)
      assert_equal(:set, iq.type)
      assert_equal(pubsub, iq.to.to_s)

      config = iq.pubsub.first_element('configure')
      assert_kind_of(Jabber::PubSub::OwnerNodeConfig, config)
      assert_kind_of(Jabber::Dataforms::XData, config.form)

      assert_equal(config.options["pubsub#title"], "Princely Musings (Atom)")
      assert_equal(config.options["pubsub#deliver_notifications"], "1")
      assert_equal(config.options["pubsub#deliver_payloads"], "1")
      assert_equal(config.options["pubsub#persist_items"], "1")
      assert_equal(config.options["pubsub#max_items"], "10")
      assert_equal(config.options["pubsub#access_model"], "open")
      assert_equal(config.options["pubsub#publish_model"], "publishers")
      assert_equal(config.options["pubsub#send_last_published_item"], "never")
      assert_equal(config.options["pubsub#presence_based_delivery"], "false")
      assert_equal(config.options["pubsub#notify_config"], "0")
      assert_equal(config.options["pubsub#notify_delete"], "0")
      assert_equal(config.options["pubsub#notify_retract"], "0")
      assert_equal(config.options["pubsub#notify_sub"], "0")
      assert_equal(config.options["pubsub#max_payload_size"], "1028")
      assert_equal(config.options["pubsub#type"], "http://www.w3.org/2005/Atom")
      assert_equal(config.options["pubsub#body_xslt"], "http://jabxslt.jabberstudio.org/atom_body.xslt")

      send("<iq type='result' from='#{iq.to}' to='#{iq.from}' id='#{iq.id}'/>")
    }

    config = Jabber::PubSub::OwnerNodeConfig.new(node)
    config.options = {
      "pubsub#title" => "Princely Musings (Atom)",
      "pubsub#deliver_notifications" => "1",
      "pubsub#deliver_payloads" => "1",
      "pubsub#persist_items" => "1",
      "pubsub#max_items" => "10",
      "pubsub#access_model" => "open",
      "pubsub#publish_model" => "publishers",
      "pubsub#send_last_published_item" => "never",
      "pubsub#presence_based_delivery" => "false",
      "pubsub#notify_config" => "0",
      "pubsub#notify_delete" => "0",
      "pubsub#notify_retract" => "0",
      "pubsub#notify_sub" => "0",
      "pubsub#max_payload_size" => "1028",
      "pubsub#type" => "http://www.w3.org/2005/Atom",
      "pubsub#body_xslt" => "http://jabxslt.jabberstudio.org/atom_body.xslt"
    }

    assert_kind_of(Jabber::PubSub::OwnerNodeConfig, config)
    h.set_config_for(node, config)
    wait_state
  end

  def test_delete_item
    pubsub = 'pubsub.example.org'
    h = PubSub::ServiceHelper.new(@client, pubsub)

    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_kind_of(Jabber::PubSub::IqPubSub, iq.pubsub)
      assert_kind_of(Jabber::PubSub::Retract, iq.pubsub.first_element('retract'))
      assert_equal(1, iq.pubsub.first_element('retract').items.size)
      assert_equal('ae890ac52d0df67ed7cfdf51b644e901', iq.pubsub.first_element('retract').items[0].id)
      send(iq.answer.set_type(:result))
    }

    h.delete_item_from('princely_musings', 'ae890ac52d0df67ed7cfdf51b644e901')
    wait_state
  end

  def test_to_s
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_equal('pubsub.example.org',h.to_s)
  end
end
