# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'
require 'xmpp4r/error'

module Jabber
  Iq.add_elementclass('error', Error)
end
