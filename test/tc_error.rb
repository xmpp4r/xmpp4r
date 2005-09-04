#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/error'
include Jabber

class ErrorTest < Test::Unit::TestCase
  def test_create
    e = Error::new
    assert_equal(nil, e.error)
    assert_equal(nil, e.code)
    assert_equal(nil, e.type)
    assert_equal(nil, e.text)
  end

  def test_create2
    e = Error::new('payment-required')
    assert_equal('payment-required', e.error)
    assert_equal(402, e.code)
    assert_equal(:auth, e.type)
    assert_equal(nil, e.text)
  end

  def test_create3
    e = Error::new('gone', 'User moved to afterlife.gov')
    assert_equal('gone', e.error)
    assert_equal(302, e.code)
    assert_equal(:modify, e.type)
    assert_equal('User moved to afterlife.gov', e.text)
  end
end
