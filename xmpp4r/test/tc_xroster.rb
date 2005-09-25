#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/x/roster'
require 'xmpp4r/jid'
include Jabber

class XRosterTest < Test::Unit::TestCase
  def test_create
    r = XRoster.new
    assert_equal('x', r.name)
    assert_equal('jabber:x:roster', r.namespace)
  end

  def test_import
    x1 = X.new
    x1.add_namespace('jabber:x:roster')
    x2 = X::import(x1)
    assert_equal(XRoster, x2.class)
  end

  def test_typed_add
    x = REXML::Element.new('x')
    x.add(REXML::Element.new('item'))
    r = XRoster.new.import(x)
    assert_kind_of(XRosterItem, r.first_element('item'))
    assert_kind_of(XRosterItem, r.typed_add(REXML::Element.new('item')))
  end
  
  def test_items
    j1 = XRosterItem.new
    assert_equal(JID.new(nil), j1.jid)
    assert_equal(nil, j1.iname)
    j2 = XRosterItem.new(JID.new('a@b/c'))
    assert_equal(JID.new('a@b/c'), j2.jid)
    assert_equal(nil, j2.iname)
    j3 = XRosterItem.new(JID.new('a@b/c'), 'Mr. Abc')
    assert_equal(JID.new('a@b/c'), j3.jid)
    assert_equal('Mr. Abc', j3.iname)
    assert_equal([], j3.groups)

    j3.groups = ['X', 'Y', 'Z']
    assert_equal(['X', 'Y', 'Z'], j3.groups)
  end
end
