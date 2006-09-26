require 'xmpp4r/pubsub/helper/servicehelper'

module Jabber
  module PubSub
    class NodeHelper < ServiceHelper
      ##
      # new(client,service,nodename)
      # client:: [Jabber::Client]
      # service:: [String]
      # nodename:: [String]
      def initialize(client,service,nodename)
         super(client,service)
      end
      
      
      
    end
  end
end