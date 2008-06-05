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
  # Test sending 'now playing' notifications
  #
  # See http://www.xmpp.org/extensions/xep-0118.html#protocol-transport,
  # example 1
  def test_send_now_playing
    artist = 'Mike Flowers Pops'
    title = 'Light My Fire'
    tune_to_send = UserTune::Tune.new(artist, title)

    h = UserTune::Helper.new(@client, nil)
    assert_kind_of(UserTune::Helper, h)

    state { |now_playing|
      assert_kind_of(Jabber::Iq, now_playing)
      assert_equal :set, now_playing.type

      assert_kind_of(Jabber::PubSub::IqPubSub,now_playing.first_element('pubsub'))
      assert_equal(Jabber::UserTune::NS_USERTUNE,now_playing.first_element('pubsub').first_element('publish').node)

      tune=now_playing.first_element('pubsub').first_element('publish').first_element('item').first_element('tune')
      assert_kind_of Jabber::UserTune::Tune,tune
      assert_equal true, tune.playing?
      assert_equal artist,tune.artist
      assert_equal title,tune.title
      assert_equal nil,tune.length
      assert_equal nil,tune.track
      assert_equal nil,tune.source
      assert_equal nil,tune.uri

      send("<iq type='result' id='#{now_playing.id}'/>")
    }
    h.now_playing(tune_to_send)
    wait_state
  end

  def test_send_stop_playing
    h = UserTune::Helper.new(@client, nil)

    state { |now_playing|
      tune = now_playing.first_element('pubsub').first_element('publish').first_element('item').first_element('tune')

      assert_kind_of Jabber::UserTune::Tune, tune
      assert_equal false, tune.playing?
      assert_equal nil, tune.artist
      assert_equal nil, tune.title
      assert_equal nil,tune.length
      assert_equal nil,tune.track
      assert_equal nil,tune.source
      assert_equal nil,tune.uri

      send("<iq type='result' id='#{now_playing.id}'/>")
    }
    h.stop_playing
    wait_state
  end
end
