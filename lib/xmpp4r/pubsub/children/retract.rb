# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/xmppelement'

module Jabber
  module PubSub

    ##
    # Retract 
    #
    # A <retract> XMPP element, see example 103 in
    # http://xmpp.org/extensions/xep-0060.html#publisher-delete 
    class Retract < XMPPElement
      name_xmlns 'retract', NS_PUBSUB
      ##
      # return the node for this publication
      def node
        attributes['node']
      end
    end
  end
end

