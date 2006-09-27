# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module PubSub
    NS_PUBSUB = 'http://jabber.org/protocol/pubsub'
    class IqPubSub < XMPPElement
      name_xmlns 'pubsub', NS_PUBSUB
      def initialize
        super(true)
      end
    end


    ##
    # Item 
    # One PubSub Item
    class Item < XMPPElement
      name_xmlns 'item'
      def initialize(id)
        super(true)
	attributes['id'] = id
      end
      def get_id
        attributes['id']
      end
      def set_id=(myid)
        attributes['id'] = myid
      end
    end

    ##
    # Items
    # a collection of Items
    class Items < XMPPElement
      name_xmlns 'items'
      def initialize
        super(true)
      end
      def get_node
        attributes['node']
      end
      def set_node=(mynodename)
        attributes['node'] = mynodename
      end
      def get_subid
        attributes['subid']
      end
      def set_subid=(mysubid)
        attributes['subid'] = mysubid
      end
      def get_max_items
        attributes['max_items']
      end
      def set_max_items=(mymaxitems)
        attributes['max_items'] = mymaxitems
      end
    end
  end
end
