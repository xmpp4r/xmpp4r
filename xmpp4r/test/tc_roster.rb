#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
require 'xmpp4r/roster'
include Jabber

class RosterTest < Test::Unit::TestCase
  def test_create
    r = Roster::new
    assert_equal(r.to_a.size, 0)
    assert_equal(r.to_a, [])
    assert_equal(r.to_s, "<query xmlns='jabber:iq:roster'/>")
  end

  def test_items
    r = Roster::new
    r.add(RosterItem.new)
    r.add(RosterItem.new(JID.new('a@b/d'), 'ABC', 'none', 'subscribe')).groups = ['a']
    itemstr = "<item jid='astro@spaceboyz.net' name='Astro' subscribtion='both'>" \
            + "<group>SpaceBoyZ</group><group>xmpp4r</group></item>"
    r.add(REXML::Document.new(itemstr).root)

    r.each { |item|
      assert_equal(item, r[item.jid])
    }

    r.to_a.each { |item|
      assert_equal(item, r[item.jid])
    }

    assert_equal(JID.new, r.to_a[0].jid)
    assert_equal(nil, r.to_a[0].iname)
    assert_equal(nil, r.to_a[0].subscription)
    assert_equal(nil, r.to_a[0].ask)

    assert_equal(JID.new('a@b'), r.to_a[1].jid)     # Resource stripped from JID
    assert_equal('ABC', r.to_a[1].iname)
    assert_equal('none', r.to_a[1].subscription)
    assert_equal('subscribe', r.to_a[1].ask)

    assert_equal(REXML::Document.new(itemstr).root.to_s, r.to_a[2].to_s)
  end
end

class RosterItemTest < Test::Unit::TestCase
  def test_create
    ri = RosterItem::new
    assert_equal(ri.jid, JID.new)
    assert_equal(ri.iname, nil)
    assert_equal(ri.subscription, nil)
    assert_equal(ri.ask, nil)

    ri = RosterItem::new(JID.new('a@b/c'), 'xyz', 'both', nil)
    assert_equal(ri.jid, JID.new('a@b'))            # Resource stripped from JID
    assert_equal(ri.iname, 'xyz')
    assert_equal(ri.subscription, 'both')
    assert_equal(ri.ask, nil)
  end

  def test_modify
    ri = RosterItem::new(JID.new('a@b/c'), 'xyz', 'both', 'subscribe')

    assert_equal(ri.jid, JID.new('a@b'))
    ri.jid = nil
    assert_equal(ri.jid, nil)

    assert_equal(ri.iname, 'xyz')
    ri.iname = nil
    assert_equal(ri.iname, nil)

    assert_equal(ri.subscription, 'both')
    ri.subscription = nil
    assert_equal(ri.subscription, nil)

    assert_equal(ri.ask, 'subscribe')
    ri.ask = nil
    assert_equal(ri.ask, nil)

  end
end
