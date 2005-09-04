#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/x/delay'
include Jabber

class XDelayTest < Test::Unit::TestCase
  def test_create1
    d = XDelay.new(false)
    assert_equal(nil, d.stamp)
    assert_equal(nil, d.from)
  end

  def test_create2
    d = XDelay.new
    # Hopefully the seconds don't change here...
    assert_equal(Time.now.to_s, d.stamp.to_s)
    assert_equal(nil, d.from)
  end

  def test_from
    d = XDelay.new
    assert_equal(nil, d.from)
    d.from = JID::new('astro@spaceboyz.net')
    assert_equal(JID::new('astro@spaceboyz.net'), d.from)
    d.from = nil
    assert_equal(nil, d.from)
  end

  def test_import
    x1 = X.new
    x1.add_namespace('jabber:x:delay')
    x2 = X::import(x1)
    assert_equal(XDelay, x2.class)
  end
end
