#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/tune/tune.rb'

class Jabber::UserTune::TuneTest < Test::Unit::TestCase
  def test_create
    artist='Mike Flowers Pops'
    title='Light My Fire'
    length=175
    track='4'
    source='A Groovy Place'
    uri='http://musicbrainz.org/track/d44110e6-4b20-4d16-9e69-74bf0e4f7106.html'
    rating=10

    t=Jabber::UserTune::Tune.new(artist,title,length,track,source,uri,rating)

    assert_kind_of Jabber::UserTune::Tune,t
    assert_equal 7,t.elements.size
    assert_equal true,t.playing?
    assert_equal artist,t.artist
    assert_equal track,t.track
    assert_equal length,t.length
    assert_equal track,t.track
    assert_equal source,t.source
    assert_equal uri,t.uri
    assert_equal rating,t.rating
  end

  def test_stop_playing
    t=Jabber::UserTune::Tune.new

    assert_kind_of Jabber::UserTune::Tune,t
    assert_equal 0,t.elements.size
    assert_equal false, t.playing?
    assert_equal nil,t.artist
    assert_equal nil,t.track
    assert_equal nil,t.length
    assert_equal nil,t.track
    assert_equal nil,t.source
    assert_equal nil,t.uri
  end

  def test_rating_edgecases
    assert_equal(0, Jabber::UserTune::Tune.new(artist,title,length,track,source,uri,-1.5).rating)
    assert_equal(10, Jabber::UserTune::Tune.new(artist,title,length,track,source,uri,11.5).rating)
    assert_equal(nil, Jabber::UserTune::Tune.new(artist,title,length,track,source,uri,'fantastic').rating)
  end

  def artist
    'Mike Flowers Pops'
  end

  def title
    'Light My Fire'
  end

  def length
    175
  end

  def track
    '4'
  end

  def source
    'A Groovy Place'
  end

  def uri
    'http://musicbrainz.org/track/d44110e6-4b20-4d16-9e69-74bf0e4f7106.html'
  end

  def rating
    10
  end
end
