#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/iq/query/version'
require 'xmpp4r/iq'
include Jabber

class IqQueryVersionTest < Test::Unit::TestCase
  def test_create_empty
    x = IqQueryVersion::new
    assert_equal('jabber:iq:version', x.namespace)
    assert_equal('', x.iname)
    assert_equal('', x.version)
    assert_equal(nil, x.os)
  end

  def test_create
    x = IqQueryVersion::new('my test', 'XP')
    assert_equal('jabber:iq:version', x.namespace)
    assert_equal('my test', x.iname)
    assert_equal('XP', x.version)
    assert_equal(nil, x.os)
  end

  def test_create_with_os
    x = IqQueryVersion::new('superbot', '1.0-final', 'FreeBSD 5.4-RELEASE-p4')
    assert_equal('jabber:iq:version', x.namespace)
    assert_equal('superbot', x.iname)
    assert_equal('1.0-final', x.version)
    assert_equal('FreeBSD 5.4-RELEASE-p4', x.os)
  end

  def test_import1
    iq = Iq::new
    q = XMLElement::new('query')
    q.add_namespace('jabber:iq:version')
    iq.add(q)
    assert_equal(IqQueryVersion, iq.query.class)
  end

  def test_import2
    iq = Iq::new
    q = XMLElement::new('query')
    q.add_namespace('jabber:iq:version')
    q.add_element('name').text = 'AstroBot'
    q.add_element('version').text = 'XP'
    q.add_element('os').text = 'FreeDOS'
    iq.add(q)
    assert_equal(IqQueryVersion, iq.query.class)
    assert_equal('AstroBot', iq.query.iname)
    assert_equal('XP', iq.query.version)
    assert_equal('FreeDOS', iq.query.os)
  end

  def test_replace
    x = IqQueryVersion::new('name', 'version', 'os')

    num = 0
    x.each_element('name') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('version') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('os') { |e| num += 1 }
    assert_equal(1, num)

    x.set_iname('N').set_version('V').set_os('O')

    num = 0
    x.each_element('name') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('version') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('os') { |e| num += 1 }
    assert_equal(1, num)

    x.set_iname(nil).set_version(nil).set_os(nil)

    num = 0
    x.each_element('name') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('version') { |e| num += 1 }
    assert_equal(1, num)
    num = 0
    x.each_element('os') { |e| num += 1 }
    assert_equal(0, num)
  end
end
