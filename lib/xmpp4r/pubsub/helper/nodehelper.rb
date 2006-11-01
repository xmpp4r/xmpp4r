# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/
#
# For a documentation of the retunvalues please look into the
# documentation of [Jabber::PubSub::ServiceHelper]
# This class is only a wrapper around [Jabber::PubSub::ServiceHelper]
# 


require 'xmpp4r/pubsub/helper/servicehelper'

module Jabber
  module PubSub
    class NodeHelper < ServiceHelper

      attr_reader :nodename
      ##
      # creats a new node  
      # new(client,service,nodename)
      # client:: [Jabber::Client]
      # service:: [String]
      # nodename:: [String]
      def initialize(client,service,nodename)
        super(client,service)
        @nodename = nodename
      end

      ##
      # configures the node
      # create(configuration=nil)
      # configuration:: [Jabber::XData]
      def create_node(configuration=nil)
        create(@nodename,configuration)
      end

      ##
      # deletes the node
      # delete
      def delete_node
        delete(@nodename)
      end

      ##
      # publishing content on this node 
      # publish_content(items)
      # items:: [REXML::Element]
      def publish_content(items)
        publish(@nodename,items)
      end

      ##
      # gets all items from the node 
      # get_all_items
      def get_all_items
        items(@nodename)
      end

      ##
      # get a count of items 
      # get_items(count)
      # count:: [Fixnum]
      def get_items(count)
        items(@nodename,count)
      end

      ##
      # get all node affiliations
      # get_affiliations
      def get_affiliations
        affiliations
      end

      ##
      # get all subscriptions on this node
      # get_subscriptions
      def get_subscriptions
        subscriptions(@nodename)
      end

      ##
      # get all subscribers subscribed on this node
      # get_subscribers
      def get_subscribers
        subscribers(@nodename)
      end

      ##
      # subscribe to this node
      # do_subscribe
      def do_subscribe
        subscribe(@nodename)
      end

      ##
      # unsubscribe from this node
      # do_unsubscribe(subid = nil)
      # subid:: [String]
      def do_unsubscribe(subid=nil)
        unsubscribe(@nodename,subid)
      end
    end
  end
end
