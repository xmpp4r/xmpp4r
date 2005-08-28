#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/message'
include Jabber

class MessageTest < Test::Unit::TestCase
  def test_create
    x = Message::new()
    assert_equal("message", x.name)
    assert_equal(nil, x.to)
    assert_equal(nil, x.body)

    x = Message::new("lucas@linux.ensimag.fr", "coucou")
    assert_equal("message", x.name)
    assert_equal("lucas@linux.ensimag.fr", x.to.to_s)
    assert_equal("coucou", x.body)
  end

  def test_body
    x = Message::new()
    assert_equal(nil, x.body)
    assert_equal(x, x.set_body("trezrze ezfrezr ezr zer ezr ezrezrez ezr z"))
    assert_equal("trezrze ezfrezr ezr zer ezr ezrezrez ezr z", x.body)
    x.body = "2"
    assert_equal("2", x.body)
  end

end
