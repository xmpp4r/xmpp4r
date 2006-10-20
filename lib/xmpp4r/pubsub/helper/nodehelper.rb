# =XMPP4R - XMPP Library for Ruby                                                                                     
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.                                         
# Website::http://home.gna.org/xmpp4r/ 

require 'xmpp4r/pubsub/helper/servicehelper'
require 'callbacks'
require 'thread'

module Jabber
  module PubSub
    class NodeHelper < ServiceHelper

      attr_reader :nodename
      ##
      # new(client,service,nodename)
      # client:: [Jabber::Client]
      # service:: [String]
      # nodename:: [String]
      def initialize(client,service,nodename)
         super(client,service)
	 @pubsubjid = service
	 @nodename = nodename
	 @event_cbs = CallbackList.new
      end
      
      ##
      # create(configuration=nil)
      # configuration:: [Jabber::XData]
      def create_node(configuration=nil)
        create(@nodename,configuration)
      end
      
      ##
      # delete
      def delete_node
        delete(@nodename)
      end
      
      ##
      # publish_content(items)
      def publish_content(items)
        publish(@nodename,items)
      end
      
      ##
      # get_all_items
      def get_all_items
        items(@nodename)
      end
      
      ##
      # get_items(count)
      # count:: [Fixnum]
      def get_items(count)
        items(@nodename,count)
      end
      
      ##
      # get_affiliations
      def get_affiliations
        affiliations
      end
      
      ##
      # get_subscriptions
      def get_subscriptions
        subscriptions(@nodename)
      end
      
      ##
      # get_subscribers
      def get_subscribers
        subscribers(@nodename)
      end
      
      ##
      # do_subscribe
      def do_subscribe 
        subscribe(@nodename)
      end
     
      ##
      # do_unsubscribe(subid = nil)
      def do_unsubscribe(subid=nil)
        unsubscribe(@nodename,subid)
      end

    private

      def handle_message(message)
        if message.from == @pubsubjid and message.first_element('event').kind_of?(Jabber::PubSub::Event) 
	  # puts message.first_element("message").first_element('event').namespace
	  event = message.first_element('event')

	  # the @event_cbs comes from our parentclass
	  @event_cbs.process(event)                                                                          
	end
      end  
    end
  end
end