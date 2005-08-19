#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
require 'xmpp4r/rosterquery'
include Jabber

class RosterQueryTest < Test::Unit::TestCase
  def test_create
    r = RosterQuery::new
    assert_equal('jabber:iq:roster', r.namespace)
    assert_equal(r.to_a.size, 0)
    assert_equal(r.to_a, [])
    assert_equal(r.to_s, "<query xmlns='jabber:iq:roster'/>")
  end

  def test_items
    r = RosterQuery::new
    r.add(RosterItem.new)
    r.add(RosterItem.new(JID.new('a@b/d'), 'ABC', :none, :subscribe)).groups = ['a']
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
    assert_equal(:none, r.to_a[1].subscription)
    assert_equal(:subscribe, r.to_a[1].ask)

    assert_equal(REXML::Document.new(itemstr).root.to_s, r.to_a[2].to_s)
  end

  def test_dupitems
    r = RosterQuery::new
    jid = JID::new('a@b')
    ri = RosterItem::new(jid, 'ab')
    r.add(ri)
    assert_equal('ab', ri.iname)
    assert_equal('ab', r[jid].iname)
    ri.iname = 'cd'
    assert_equal('cd', ri.iname)
    assert_equal('ab', r[jid].iname)
    r.add(ri)
    assert_equal('cd', r[jid].iname)
  end
end

class RosterItemTest < Test::Unit::TestCase
  def test_create
    ri = RosterItem::new
    assert_equal(JID.new, ri.jid)
    assert_equal(nil, ri.iname)
    assert_equal(nil, ri.subscription)
    assert_equal(nil, ri.ask)

    ri = RosterItem::new(JID.new('a@b/c'), 'xyz', :both, nil)
    assert_equal(JID.new('a@b'), ri.jid)            # Resource stripped from JID
    assert_equal('xyz', ri.iname)
    assert_equal(:both, ri.subscription)
    assert_equal(nil, ri.ask)
  end

  def test_modify
    ri = RosterItem::new(JID.new('a@b/c'), 'xyz', :both, :subscribe)

    assert_equal(JID.new('a@b'), ri.jid)
    ri.jid = nil
    assert_equal(JID::new, ri.jid)

    assert_equal('xyz', ri.iname)
    ri.iname = nil
    assert_equal(nil, ri.iname)

    assert_equal(:both, ri.subscription)
    ri.subscription = nil
    assert_equal(nil, ri.subscription)

    assert_equal(:subscribe, ri.ask)
    ri.ask = nil
    assert_equal(nil, ri.ask)

  end
end
