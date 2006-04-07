#!/usr/bin/ruby


require 'lib/clienttester'
require 'xmpp4r/helpers/mucclient'
include Jabber

class MUCClientTest < Test::Unit::TestCase
  include ClientTester

  def test_new1
    m = Helpers::MUCClient.new(@client)
    assert_equal(nil, m.jid)
    assert_equal(nil, m.my_jid)
    assert_equal({}, m.roster)
    assert(!m.active?)
  end

  # JEP-0045: 6.3 Entering a Room
  def test_jep0045_6_3
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/thirdwitch'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit' to='hag66@shakespeare.lit/pda' type='error'>" + 
           "<error code='400' type='modify'>" +
           "<jid-malformed xmlns='urn:ietf:params:xml:ns:xmpp-stanzas'/>" +
           "</error></presence>")
    }
    state { |pres|
      assert_kind_of(Presence, pres)
      assert_equal(JID.new('hag66@shakespeare.lit/pda'), pres.from)
      assert_equal(JID.new('darkcave@macbeth.shakespeare.lit/thirdwitch'), pres.to)
      send("<presence from='darkcave@macbeth.shakespeare.lit/firstwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='owner' role='moderator'/></x>" +
          "</presence>" +
          "<presence from='darkcave@macbeth.shakespeare.lit/secondwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='admin' role='moderator'/></x>" +
          "</presence>" +
          "<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='hag66@shakespeare.lit/pda'>" +
          "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='member' role='participant'/></x>" +
          "</presence>")
    }


    m = Helpers::MUCClient.new(@client)
    m.my_jid = 'hag66@shakespeare.lit/pda'
    assert(!m.active?)

    assert_raises(ErrorException) {
      m.join('darkcave@macbeth.shakespeare.lit/thirdwitch')
    }
    assert(!m.active?)

    assert_equal(m, m.join('darkcave@macbeth.shakespeare.lit/thirdwitch'))
    assert(m.active?)
    assert_equal(3, m.roster.size)
    m.roster.each { |resource,pres|
      assert_equal(resource, pres.from.resource)
      assert_equal('darkcave', pres.from.node)
      assert_equal('macbeth.shakespeare.lit', pres.from.domain)
      assert_kind_of(String, resource)
      assert_kind_of(Presence, pres)
      assert(%w(firstwitch secondwitch thirdwitch).include?(resource))
      assert_kind_of(XMucUser, pres.x)
      assert_kind_of(Array, pres.x.items)
      assert_equal(1, pres.x.items.size)
    }
    assert_equal(:owner, m.roster['firstwitch'].x.items[0].affiliation)
    assert_equal(:moderator, m.roster['firstwitch'].x.items[0].role)
    assert_equal(:admin, m.roster['secondwitch'].x.items[0].affiliation)
    assert_equal(:moderator, m.roster['secondwitch'].x.items[0].role)
    assert_equal(:member, m.roster['thirdwitch'].x.items[0].affiliation)
    assert_equal(:participant, m.roster['thirdwitch'].x.items[0].role)
    assert_nil(m.roster['thirdwitch'].x.items[0].jid)

    send("<presence from='darkcave@macbeth.shakespeare.lit/thirdwitch' to='crone1@shakespeare.lit/desktop'>" +
         "<x xmlns='http://jabber.org/protocol/muc#user'><item affiliation='none' jid='hag66@shakespeare.lit/pda' role='participant'/></x>" +
         "</presence>")
    sleep 0.1
    assert_equal(3, m.roster.size)
    assert_equal(:none, m.roster['thirdwitch'].x.items[0].affiliation)
    assert_equal(:participant, m.roster['thirdwitch'].x.items[0].role)
    assert_equal(JID.new('hag66@shakespeare.lit/pda'), m.roster['thirdwitch'].x.items[0].jid)
  end
end
