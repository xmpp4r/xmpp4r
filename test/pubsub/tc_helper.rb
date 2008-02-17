#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/pubsub/helper/servicehelper'
include Jabber

Jabber.debug = true



class PubSub::ServiceHelperTest < Test::Unit::TestCase
  include ClientTester

  ##
  # subscribe_to
  def test_subscribe
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(Jabber::PubSub::ServiceHelper,h)
    state { |iq|
      assert_kind_of(Jabber::Iq,iq)
      assert_equal(:set,iq.type)
      assert_equal(1, iq.children.size)
      assert_equal('http://jabber.org/protocol/pubsub', iq.pubsub.namespace)
      assert_equal(1, iq.pubsub.children.size)
      assert_equal('subscribe',iq.pubsub.children.first.name)
      assert_equal('princely_musings',iq.pubsub.children.first.attributes['node'])
      #assert_equal(@client.jid.strip.to_s,iq.pubsub.children.first.attributes['jid'])
      assert_equal(iq.from,iq.pubsub.children.first.attributes['jid'])
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
            <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <subscription node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from}'
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

=begin
  # not implemented yet
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
		        <subscription node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from}'
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
=end 

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
                <subscription node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from}'
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
  # unsubscribe_from
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
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'>
            <pubsub xmlns='http://jabber.org/protocol/pubsub'>
                <unsubscribe node='#{iq.pubsub.children.first.attributes['node']}' jid='#{iq.from}'/>
           </pubsub>
           </iq>")
    }
    unsubscribe = h.unsubscribe_from('princely_musings')
    assert_equal(true,unsubscribe)
    wait_state
  end



  def test_create
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_kind_of(PubSub::ServiceHelper, h)

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
    assert_equal('mynode', h.create_node('mynode'))
    wait_state
  end

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

  def test_publish
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
      assert_equal(1, iq.pubsub.children[0].children[0].children.size)
      assert_equal(item1.children.to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.publish_item_to('mynode', item1)
    wait_state
  end
  
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
      assert_equal(item1.children.to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.publish_item_with_id_to('mynode', item1,"blubb")
    wait_state
  end

=begin
# i dont know how to catch the runtime error - if you know please fix :)
  def test_publish_pubsub_item_with_id_and_produce_an_error
    item1 = "foobar"
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
      assert_equal(item1.children.to_s, iq.pubsub.children[0].children[0].children[0].to_s)
      send("<iq type='result' to='#{iq.from}' from='#{iq.to}' id='#{iq.id}'/>")
    }
    h.publish_item_with_id_to('mynode', item1,"blubb")
    wait_state
  end
=end

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
   
  ##
  # get_subscriptions_from
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
    assert_equal(JID::new("hamlet@denmark.lit"),s[0].jid)
    assert_equal("123-abc",s[2].subid)
    wait_state
  end

  
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
    assert_equal(JID::new("francisco@denmark.lit"),s[0].jid)
    assert_equal("node1",s[0].node)

    wait_state
  end

  
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

  def test_to_s
    h = PubSub::ServiceHelper.new(@client,'pubsub.example.org')
    assert_equal('pubsub.example.org',h.to_s)
  end
  
end
