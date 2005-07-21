#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/client'
include Jabber

class ClientTest < Test::Unit::TestCase
  def test_client1
    c = Client::new(JID::new('lucas@localhost/res'))
    c.connect
    puts "Authed" if c.auth('pw')
  end
end
