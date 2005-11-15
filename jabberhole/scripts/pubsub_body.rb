#
# This script adds a body to PubSub (JEP-0060) messages
#
# When you're experimenting with Publish-Subscribe, you might
# notice, that PubSub notifications do not posses a <body/>
# element, so your client won't display it.
#
# This script takes the stanza's source as a String and puts
# it into the message's <body/>.
#

Proxy.add_server_callback { |stanza,cl|
  if stanza.kind_of?(Jabber::Message) and (stanza.first_element('body') == nil)

    is_pubsub = false
    stanza.each_element { |e|
      is_pubsub = true if e.namespace.index('http://jabber.org/protocol/pubsub')
    }

    if is_pubsub
      xmlsrc = stanza.to_s
      stanza.body = xmlsrc
    end
  end

  false
}
