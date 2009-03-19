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
      # get the node for this retraction
      def node
        attributes['node']
      end

      ##
      # set the node for this retraction
      def node=(s)
        attributes['node'] = s
      end

      ##
      # Get <item/> children
      def items
        res = []
        each_element('item') { |item|
          res << item
        }
        res
      end
    end
  end
end

