#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/presence'
require 'xmpp4r/jid'
include Jabber

class PresenceTest < Test::Unit::TestCase
  def test_create
    x = Presence::new()
    assert_equal("presence", x.name)
    assert_equal(nil, x.to)
    assert_equal(nil, x.show)
    assert_equal(nil, x.status)
    assert_equal(nil, x.priority)

    x = Presence::new(JID::new("lucas@linux.ensimag.fr"), "away", "I am away", 23)
    assert_equal("presence", x.name)
    assert_equal("lucas@linux.ensimag.fr", x.to.to_s)
    assert_equal("away", x.show)
    assert_equal("I am away", x.status)
    assert_equal(23, x.priority)
  end

  def test_show
    x = Presence::new()
    assert_equal(nil, x.status)
    x.show = "a"
    assert_equal("a", x.show)
    x.each_element('show') { |e| assert(e.class == REXML::Element, "<show/> is not REXML::Element") }
    x.show = nil
    assert_equal(nil, x.show)
    x.each_element('show') { |e| assert(true, "<show/> exists after 'show=nil'") }
    x.show = nil
    assert_equal(nil, x.show)
  end

  def test_status
    x = Presence::new()
    assert_equal(nil, x.status)
    x.status = "b"
    assert_equal("b", x.status)
    x.each_element('status') { |e| assert(e.class == REXML::Element, "<status/> is not REXML::Element") }
    x.status = nil
    assert_equal(nil, x.status)
    x.each_element('status') { |e| assert(true, "<status/> exists after 'show=nil'") }
    x.status = nil
    assert_equal(nil, x.status)
  end

  def test_priority
    x = Presence::new()
    assert_equal(nil, x.priority)
    x.priority = 5
    assert_equal(5, x.priority)
    x.each_element('priority') { |e| assert(e.class == REXML::Element, "<priority/> is not REXML::Element") }
    x.priority = "5"
    assert_equal(5, x.priority)
    x.priority = nil
    assert_equal(nil, x.priority)
  end

  def test_type
    x = Presence::new()
    assert_equal(nil, x.type)
    x.type = "delete"
    assert_equal("delete", x.type)
    x.type = nil
    assert_equal(nil, x.type)
    x.each_element('type') { |e| assert(true, "<type/> exists after 'show=nil'") }
    x.type = nil
    assert_equal(nil, x.type)
  end

  def test_chaining
    x = Presence::new()
    x.set_show("xa").set_status("Plundering the fridge.").set_priority(0)
    assert_equal("xa", x.show)
    assert_equal("Plundering the fridge.", x.status)
    assert_equal(0, x.priority)
  end
end
