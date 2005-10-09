# JabberHole Service Discovery example
#
# This example gives your client the ability to be browsed
# by others via Service Discovery.
#
# You *cannot* browse yourself as only stanzas from servers
# are intercepted!


require 'xmpp4r/iq/query/discoinfo'
require 'xmpp4r/iq/query/discoitems'

# Add callback for stanzas from server
Proxy.add_server_callback { |stanza,cl|

  # Filter for <iq type='get'/>
  if stanza.kind_of?(Jabber::Iq) and stanza.type == :get
    
    # Is this a query for discovery information?
    if stanza.query.kind_of?(Jabber::IqQueryDiscoInfo)
      # Compose answer
      answer = stanza.answer
      answer.type = :result
      # Discovery identity
      answer.query.add(Jabber::DiscoIdentity.new('client', 'JabberHole Service Discovery', 'pc'))
      # This client supports the three main stanzas
      answer.query.add(Jabber::DiscoFeature.new('message'))
      answer.query.add(Jabber::DiscoFeature.new('presence'))
      answer.query.add(Jabber::DiscoFeature.new('iq'))
      # This client supports Service Discovery
      answer.query.add(Jabber::DiscoFeature.new(Jabber::IqQueryDiscoInfo.new.namespace))
      answer.query.add(Jabber::DiscoFeature.new(Jabber::IqQueryDiscoItems.new.namespace))
      # Send our answer
      cl.server_conn.send(answer)
      # Handled request, no further actions to be taken
      true

    # Is this a query for discovery items?
    elsif stanza.query.kind_of?(Jabber::IqQueryDiscoItems)
      # Compose answer
      answer = stanza.answer
      answer.type = :result
      # Send the answer unmodified (no subitems)
      cl.server_conn.send(answer)
      # Handled request, no further actions to be taken
      true

    else
      # Pass all queries that are neither discovery
      # information nor items
      false
    end
  else
    # Pass all non-<iq type='get'/> stanzas
    false
  end
}

