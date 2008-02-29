
$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r/discovery'
require 'xmpp4r/caps/helper/helper'
include Jabber

class Caps::HelperTest < Test::Unit::TestCase
  include ClientTester

  ##
  # Walk through the client/ server conversation defined
  # in http://www.xmpp.org/extensions/xep-0115.html#usecases
  # and assert conformance.
  def test_caps_reply
    # This will be invoked by 'wait_state' below...
    state { |presence|
      assert_kind_of(Jabber::Presence, presence)
      c=presence.first_element('c')
      assert_kind_of(Jabber::Caps::C, c)
      
      # see http://www.xmpp.org/extensions/xep-0115.html#ver
      assert_equal('8RovUdtOmiAjzj+xI7SK5BCw3A8=', c.ver)

      # version 1.5 of xep 0115 indicates that the <c /> stanzq MUST feature a 'hash' attribute
      assert_equal('sha-1', c.hash)

      assert_equal("http://home.gna.org/xmpp4r/##{Jabber::XMPP4R_VERSION}", c.node)
      
      send(iq_discovering_capabilities)
    }

    # Construct Caps::Helper which will send a <presence>
    # stanza (with embedded <c/> advert) to the 'server'
    h = Caps::Helper.new(@client, identities, features)
    
    # The 'server' will receive the <presence> stanza and
    # yield it to the 'state' block above, where an <iq> query
    # will be sent back to the 'client,' to discover its capabilities.
    # Wait here until the block has been executed.
    wait_state  

    # The Caps::Helper will process the <iq> query from the 'server'
    # and reply with an <iq> result providing the details of its
    # identities and features.
 
    state { |iq|
      assert_kind_of(Jabber::Iq, iq)
      assert_equal(:result, iq.type)
      assert_equal('1867999907', iq.id)
      assert_equal('new-big-computer.local', iq.to.to_s)

      assert_kind_of(Jabber::Discovery::IqQueryDiscoInfo, iq.query)
      assert_equal(iq.query.identities.size, identities.size)
      get_category_iname_type = lambda{ |i| [i.category,i.iname,i.type] }
      assert_equal(iq.query.identities.map(&get_category_iname_type).sort!, identities.map(&get_category_iname_type).sort!)

      assert_equal(3, iq.query.features.size)
      get_var=lambda { |f| f.var }
      assert_equal(iq.query.features.sort, features.map(&get_var).sort)
    }

    # The 'server' will receive the <iq> result from the
    # 'client' and yield it to the block above. Wait here
    # until that block exits.
    wait_state
  end

  def test_custom_node
    client_id='http://new-big-computer.local/client#321'
  
    state { |presence|
      c = presence.first_element('c')
      assert_kind_of(Jabber::Caps::C, c)      
      assert_equal( client_id, c.node)
      assert_equal( '8RovUdtOmiAjzj+xI7SK5BCw3A8=', c.ver)
    }
    h = Caps::Helper.new(@client, identities, features, client_id)
    wait_state
  end

  def identities
    [Jabber::Discovery::Identity.new('client', nil, 'pc')]
  end

  def features
    [Jabber::Discovery::Feature.new("http://jabber.org/protocol/disco#info"), Jabber::Discovery::Feature.new("http://jabber.org/protocol/disco#items"), Jabber::Discovery::Feature.new("http://jabber.org/protocol/muc")]
  end

  def iq_discovering_capabilities
    "<iq from='new-big-computer.local' type='get' to='matt@new-big-computer.local/capable_client' id='1867999907' xmlns='jabber:client'><query xmlns='http://jabber.org/protocol/disco#info'/></iq>"
  end
end
