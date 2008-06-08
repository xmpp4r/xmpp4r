#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/error'
require 'xmpp4r/errorexception'
include Jabber

class ErrorExceptionTest < Test::Unit::TestCase

  def test_create_with_empty_error
    e = Error::new()
    ee = ErrorException::new(e)
    assert_equal(nil, e.error)
  end

  def test_create_with_error_code
    e = Error::new('payment-required')
    ee = ErrorException::new(e)
    assert_equal("payment-required: ", ee.to_s)
  end

  def test_create_invalid
    assert_raise(RuntimeError) {
      e = Error::new('invalid error')
      ee = ErrorException::new(e)
    }
  end

  def test_to_s_with_error_code_but_no_text
    e = Error::new('payment-required')
    ee = ErrorException::new(e)
    assert_equal("payment-required: ", ee.to_s)
    assert_equal('payment-required', e.error)
    assert_equal(402, ee.error.code)
    assert_equal(:auth, ee.error.type)
    assert_equal(nil, ee.error.text)
  end

  def test_to_s_with_error_code_and_text
    e = Error::new('payment-required', 'cuz you are a deadbeat.')
    ee = ErrorException::new(e)
    assert_equal("payment-required: cuz you are a deadbeat.", ee.to_s)
    assert_equal('payment-required', e.error)
    assert_equal(402, ee.error.code)
    assert_equal(:auth, ee.error.type)
    assert_equal("cuz you are a deadbeat.", ee.error.text)
  end

end
