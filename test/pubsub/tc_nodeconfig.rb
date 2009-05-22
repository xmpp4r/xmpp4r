#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/pubsub/children/node_config'
require 'xmpp4r/dataforms'
include Jabber

# Jabber.debug = true

class PubSub::NodeConfigTest < Test::Unit::TestCase
  include ClientTester

  def test_create()
    config = PubSub::NodeConfig.new()
    assert_nil(config.form)
    assert_nil(config.node)
    assert_equal({}, config.options)
  end

  def test_create_with_options
    options = {'pubsub#access_model'=>'open'}

    config = PubSub::NodeConfig.new(nil, options)
    assert_kind_of(Jabber::Dataforms::XData, config.form)
    assert_equal(options, config.options)
    assert_equal(:submit, config.form.type)
    assert_equal('http://jabber.org/protocol/pubsub#node_config', config.form.field('FORM_TYPE').values.first)
  end

  def test_create_with_options_and_node
    node = 'mynode'
    options = {'pubsub#access_model'=>'open'}

    config = PubSub::NodeConfig.new(node, options)
    assert_equal(node, config.node)
    assert_kind_of(Jabber::Dataforms::XData, config.form)
    assert_equal(options, config.options)
    assert_equal(:submit, config.form.type)
    assert_equal('http://jabber.org/protocol/pubsub#node_config', config.form.field('FORM_TYPE').values.first)
  end

  def test_set_options
    options = {'pubsub#access_model'=>'open'}
    config = PubSub::NodeConfig.new()
    config.options = options
    assert_kind_of(Jabber::Dataforms::XData, config.form)
    assert_equal(options, config.options)
  end

  def test_create_with_array_in_options
    options = {'pubsub#collection'=>['parent1','parent2']}
    config = PubSub::OwnerNodeConfig.new(nil, options)

    assert_equal(options, config.options)
  end
end
