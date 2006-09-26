# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/xmppelement'

module Jabber
  ##
  # A class used to build/parse <x/> elements
  #
  # These elements may occur as "attachments"
  # in [Message] and [Presence] stanzas
  class X < XMPPElement
    name_xmlns 'x'

    def initialize
      super(true)
    end
  end
end
