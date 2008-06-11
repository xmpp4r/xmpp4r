#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/pubsub/children/subscription_config'
require 'xmpp4r/dataforms'
include Jabber

# Jabber.debug = true

class PubSub::SubscriptionConfigTest < Test::Unit::TestCase
  include ClientTester

  def test_create()
    config = PubSub::SubscriptionConfig.new()
    assert_nil(config.form)
    assert_nil(config.node)
    assert_equal({}, config.options)
  end

  def test_create_with_options
    node = 'mynode'
    jid = 'test@test.com'
    options = {'pubsub#access_model'=>'open'}
    subid = '004-yyy'

    config = PubSub::SubscriptionConfig.new(node, jid, options, subid)
    assert_equal(node, config.node)
    assert_equal(subid, config.subid)
    assert_kind_of(Jabber::JID, config.jid)
    assert_equal(Jabber::JID.new(jid), config.jid)
    assert_kind_of(Jabber::Dataforms::XData, config.form)
    assert_equal(options, config.options)
    assert_equal(:submit, config.form.type)
    assert_equal('http://jabber.org/protocol/pubsub#subscribe_options', config.form.field('FORM_TYPE').values.first)
  end
end
