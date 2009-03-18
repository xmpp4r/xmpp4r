#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r'
require 'xmpp4r/last/helper/helper'
include Jabber


class LastActivity::HelperTest < Test::Unit::TestCase
  include ClientTester

  def test_simple_query
    state { |iq|
      assert_kind_of(Iq, iq)
      assert_equal(JID.new('juliet@capulet.com'), iq.to)
      assert_equal(:get, iq.type)
      assert_kind_of(LastActivity::IqQueryLastActivity, iq.query)
      send("
<iq type='result' from='#{iq.to}' to='#{iq.from}' id='#{iq.id}'>
  <query xmlns='jabber:iq:last' seconds='903'/>
</iq>")
    }

    res = LastActivity::Helper.new(@client).get_last_activity_from('juliet@capulet.com')
    wait_state
    assert_equal(903, res.seconds)
    assert_nil(res.text)
  end

  def test_text_query
    state { |iq|
      send("
<iq type='result' from='#{iq.to}' to='#{iq.from}' id='#{iq.id}'>
  <query xmlns='jabber:iq:last' seconds='903'>Heading Home</query>
</iq>")
    }

    res = LastActivity::Helper.new(@client).get_last_activity_from('juliet@capulet.com')
    wait_state
    assert_equal(903, res.seconds)
    assert_equal('Heading Home', res.text)
  end

  def test_empty_query
    state { |iq|
      send("
<iq type='result' from='#{iq.to}' to='#{iq.from}' id='#{iq.id}'>
  <query xmlns='jabber:iq:last'/>
</iq>")
    }

    res = LastActivity::Helper.new(@client).get_last_activity_from('juliet@capulet.com')
    wait_state
    assert_nil(res.seconds)
    assert_nil(res.text)
  end

  def test_forbidden_query
    state { |iq|
      send("
<iq type='error' from='#{iq.to}' to='#{iq.from}' id='#{iq.id}'>
  <error type='auth'>
    <forbidden xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>
  </error>
</iq>")
    }

    assert_raises(ServerError) { LastActivity::Helper.new(@client).get_last_activity_from('juliet@capulet.com') }
  end

end
