#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/iq'
include Jabber

class IqTest < Test::Unit::TestCase
  def test_create
    x = Iq::new()
    assert_equal("iq", x.name)
    assert_equal("<iq/>", x.to_s)
  end

  def test_iqauth
    x = Iq::new_authset(JID::new('node@domain/resource'), 'password')
    assert_equal("<iq type='set'><query xmlns='jabber:iq:auth'><username>node</username><password>password</password><resource>resource</resource></query></iq>", x.to_s)
  end

  def test_query
    x = Iq::new(:set)
    query = REXML::Element::new('query')
    query.add_namespace('jabber:iq:auth')
    x.add(query)
    assert_equal(query.to_s, x.query.to_s)
    assert_equal('jabber:iq:auth', x.queryns)
  end
end
