#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/iq/query/roster'
include Jabber

class IqQueryRosterTest < Test::Unit::TestCase
  def test_create
    r = IqQueryRoster::new
    assert_equal('jabber:iq:roster', r.namespace)
    assert_equal(r.to_a.size, 0)
    assert_equal(r.to_a, [])
    assert_equal(r.to_s, "<query xmlns='jabber:iq:roster'/>")
  end

  def test_import
    iq = Iq::new
    q = REXML::Element::new('query')
    q.add_namespace('jabber:iq:roster')
    iq.add(q)
    assert_equal(IqQueryRoster, iq.query.class)
  end

  def test_items
    r = IqQueryRoster::new
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
    r = IqQueryRoster::new
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

  def test_groupdeletion
    ri = RosterItem::new
    g1 = ['a', 'b', 'c']
    ri.groups = g1
    assert_equal(g1, ri.groups.sort)
    g2 = ['c', 'd', 'e']
    ri.groups = g2
    assert_equal(g2, ri.groups.sort)
  end

  def test_dupgroups
    ri = RosterItem::new
    mygroups = ['a', 'a', 'b']
    ri.groups = mygroups
    assert_equal(mygroups.uniq, ri.groups)
  end
end
