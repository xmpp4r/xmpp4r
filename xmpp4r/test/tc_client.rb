#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r'
include Jabber

class ClientTest < Test::Unit::TestCase
  def test_client1
    assert_nothing_raised("Couldn't connect") do
      c = Client::new(JID::new('client1@localhost/res'))
      c.connect
      assert(c.auth('pw'), "Auth failed")
    end
  end
end
