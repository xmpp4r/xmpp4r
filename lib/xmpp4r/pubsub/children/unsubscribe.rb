# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io

require 'xmpp4r/iq'

module Jabber
  module PubSub
    ##
    # Unsubscribe
    class Unsubscribe < XMPPElement
      name_xmlns 'unsubscribe'
      def initialize(myjid=nil,mynode=nil,mysubid=nil)
        super()
        jid = myjid
        node =  mynode
        subid = mysubid
      end

      ##
      # shows the jid
      # return:: [String]
      def jid
        (a = attribute('jid')).nil? ? a : JID.new(a.value)
      end

      ##
      # sets the jid
      # =:: [Jabber::JID] or [String]
      def jid=(myjid)
        add_attribute('jid', myjid ? myjid.to_s : nil)
      end

      ##
      # shows the node
      # return:: [String]
      def node
        attributes['node']
      end

      ##
      # sets the node
      # =:: [String]
      def node=(mynode)
        attributes['node'] = mynode
      end

      ##
      # shows the subid
      # return:: [String]
      def subid
        attributes['subid']
      end

      ##
      # sets the subid
      # =:: [String]
      def subid=(mysubid)
        attributes['subid'] = mysubid
      end
    end
  end
end
