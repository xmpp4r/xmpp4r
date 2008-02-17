# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module PubSub
    ##
    # Item
    # One PubSub Item
    class Item < XMPPElement
      name_xmlns 'item'
      def initialize(id = nil,node = nil)
        super()
        attributes['node'] = node
        attributes['id'] = id
      end

      ##
      # returns itemid
      def id
        attributes['id']
      end

      ##
      # set item id
      # id:: [String]
      def id=(myid)
        attributes['id'] = myid
      end
      
      ##
      # returns node
      def node
        attributes['node']
      end
      
      ##
      # sets node
      # node:: [String]
      def node=(mynode)
        attributes['node'] = mynode
      end
      
    end
  end
end
