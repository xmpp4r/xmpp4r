# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module PubSub
    ##
    # Subscription
    class Subscription < XMPPElement
      name_xmlns 'subscription', NS_PUBSUB
      def initialize(myjid=nil,mynode=nil,mysubid=nil,mysubscription=nil)
        super(true)
        jid = myjid
	node =  mynode
	subid =  mysubid
	state = mysubscription
      end
      
      ##
      # shows the jid
      # return:: [String]
      def jid
        attributes['jid']
      end
      
      ##
      # sets the jid
      # =:: [Jabber::JID] or [String]
      def jid=(myjid)
        attributes['jid'] = myjid
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
      
      ##
      # shows the state
      # return:: [Symbol] (:none,:pending,:subscribed,:unconfigured) 
      def state                                                                                                            
          # each child of event
          # this should interate only one time
          case attributes['subscription']
              when 'none'      		then return :none
              when 'pending'   		then return :pending
              when 'subscribed'         then return :subscribed
              when 'unconfigured'       then return :unconfigured
              else return nil
          end
      end
      
      ##
      # sets the state
      # =:: [String] or [Symbol]
      def state=(mystate)
        attributes['subscription'] = mystate.to_s
      end
      
      alias subscription state
      
      ##
      # the subscription need a configuration?
      # return:: true or false
      def need_configuration?
        self.first_element('subscribe-options').first_element('required') ? true : false
      end
      
      ##
      # is a approval from the nodeadmin needed?
      # return:: true or false
      def need_approval?
        state == :pending ? true : false
      end
    end
  end
end