# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module PubSub
    NS_PUBSUB = 'http://jabber.org/protocol/pubsub'
    class IqPubSub < REXML::Element
      ##
      # Initialize a <pubsub/> element with the PubSub namespace
      def initialize
        super("pubsub")
        add_namespace(NS_PUBSUB)
      end

      ##
      # element:: [REXML::Element] to import
      # result:: [IqPubSub] with all attributes and children copied from element
      def self.import(element)
        new.import(element)
      end
    end
  end
end
