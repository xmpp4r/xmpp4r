# JabberHole Version modify example
#
# This user-script modifies jabber:iq:version results from
# you.


require 'xmpp4r/iq/query/version'

# Add a callback for stanzas from client to server
Proxy.add_client_callback { |stanza,cl|

  # Filter <iq/> stanzas with jabber:iq:version query
  # results
  if stanza.kind_of?(Jabber::Iq) and stanza.type == :result and stanza.query.kind_of?(Jabber::IqQueryVersion)
    # Software name is prepended with "JabberHole/"
    stanza.query.iname = "JabberHole/#{stanza.query.iname}"
    # Software version is multiplied by 23
    stanza.query.version = stanza.query.version.gsub(/\d+/) { |v| (v.to_i * 23).to_s }
    # Operating system is set to "XMPP4R OS"
    stanza.query.os = 'XMPP4R OS'
  end

  # We handled the stanza, but it can be forwarded normally
  false
}
