#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/tune/helper/helper'
require 'xmpp4r/tune/tune'
include Jabber

#Jabber::debug=true

class UserTune::HelperTest < Test::Unit::TestCase
  include ClientTester

  ##
  # Test receiving 'now playing' notifications
  #
  # See http://www.xmpp.org/extensions/xep-0118.html#protocol-transport,
  # example 1
  def test_recv_now_playing
    state { |presence|
      send(deliver_usertune)
    }

    query_waiter = Semaphore.new

    h = UserTune::Helper.new(@client, 'stpeter@jabber.org')
    h.add_usertune_callback do |tune|
      assert_kind_of Jabber::UserTune::Tune, tune
      assert_equal true, tune.playing?
      assert_equal 'Yes', tune.artist
      assert_equal 686, tune.length
      assert_equal 'Yessongs', tune.source
      assert_equal 'Heart of the Sunrise', tune.title
      assert_equal '3', tune.track
      assert_equal 'http://www.yesworld.com/lyrics/Fragile.html#9',tune.uri
      query_waiter.run
    end
    @client.send Jabber::Presence.new
    wait_state

    query_waiter.wait
  end

  # see example 2 from http://www.xmpp.org/extensions/xep-0118.html#protocol-transport
  def deliver_usertune
    "<message
    from='stpeter@jabber.org'
    to='maineboy@jabber.org'>
    <event xmlns='http://jabber.org/protocol/pubsub#event'>
    <items node='http://jabber.org/protocol/tune'>
      <item id='bffe6584-0f9c-11dc-84ba-001143d5d5db'>
        <tune xmlns='http://jabber.org/protocol/tune'>
          <artist>Yes</artist>
          <length>686</length>
          <source>Yessongs</source>
          <title>Heart of the Sunrise</title>
          <track>3</track>
          <uri>http://www.yesworld.com/lyrics/Fragile.html#9</uri>
        </tune>
      </item>
    </items>
    </event>
    </message>"
  end

  # an example from the Wild
  def psi_usertune
    "<message from='admin@new-big-computer.local' to='matt@new-big-computer.local/trackbot' xmlns='jabber:client'><event xmlns='http://jabber.org/protocol/pubsub#event'><items node='http://jabber.org/protocol/tune'><item id='current'>

    <tune xmlns='http://jabber.org/protocol/tune'>





    <artist>Wes Montgomery</artist><title>Jingles</title><source>Bags Meets Wes</source><track>8</track><length>410</length></tune></item></items></event></message>"
  end
end
