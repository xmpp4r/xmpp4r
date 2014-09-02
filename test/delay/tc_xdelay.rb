#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/delay/x/delay'
include Jabber

class XDelayTest < Test::Unit::TestCase
  def test_create1
    d = Delay::XDelay.new(false)
    assert_equal(nil, d.stamp)
    assert_equal(nil, d.from)
    assert_equal('jabber:x:delay', d.namespace)
  end

  def test_create2
    d = Delay::XDelay.new
    # Hopefully the seconds don't change here...
    assert_equal(Time.now.getutc.to_s, d.stamp.to_s)
    assert_equal(nil, d.from)
    assert_equal('jabber:x:delay', d.namespace)
  end

  def test_from
    d = Delay::XDelay.new
    assert_equal(nil, d.from)
    d.from = JID.new('astro@spaceboyz.net')
    assert_equal(JID.new('astro@spaceboyz.net'), d.from)
    assert_equal(d, d.set_from(nil))
    assert_equal(nil, d.from)
  end

  def test_stamp
    d = Delay::XDelay.new(false)
    assert_equal(nil, d.stamp)
    now = Time.now
    d.stamp = now
    assert_equal(now.getutc.to_s, d.stamp.to_s)
    assert_equal(d, d.set_stamp(nil))
    assert_equal(nil, d.stamp)
  end

  # http://xmpp.org/extensions/xep-0091.html has been obsoleted by the XMPP Standards Foundation
  # http://xmpp.org/extensions/xep-0203.html replaces it, and modifies the stamp to be
  # the dateTime format specified in XEP-0082 and MUST be expressed in UTC.
  def test_stamp_format
    d = Delay::XDelay.new(false)
    now = Time.now
    xep0203_stamp = now.getutc.strftime "%Y-%m-%dT%H:%M:%SZ"

    d.stamp = now.getlocal
    assert_equal(xep0203_stamp, d.attributes['stamp'])

    d.stamp = now.getutc
    assert_equal(xep0203_stamp, d.attributes['stamp'])
  end

  def test_import
    x1 = X.new
    x1.add_namespace('jabber:x:delay')
    x2 = X::import(x1)
    assert_equal(Delay::XDelay, x2.class)
  end
end
