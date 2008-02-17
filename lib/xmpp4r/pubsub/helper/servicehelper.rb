# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/
#
# It's recommented to read the XEP-0066 before you use this Helper. (Maybe its 
# better not use the helper for now ) ;)
# The whole code is buggy - you have been warned!
# 
# Maybe the following structure is good 
# ( taken form the xep-0060 )
#
# entity usecases
#  retrieve all suscriptions
#  retrieve all affiliations
# NOTE: the disco stuff will done by the nodebrowserhelper
# subscriber usecases 
#   subscribe
#   unsubscribe
#   configure subscription options
#   retrive items from a node
# publisher usecases
#   publish a item to a node
#   delete a item from a node
# owner usecases
#   create a node
#   configure a node
#   request default configuration options
#   delete a node
#   purge all node items
#   manage subscription requests
#   process pending subscriptions
#   manage subscriptions 
#   manage affiliations
#  
# collection nodes
#    
#  If someone want to implement something i think its better to do this in  
#  this order because everyone who reads the xep-0060 do know where to search in the file
# 
require 'xmpp4r/pubsub/iq/pubsub'
require 'xmpp4r/pubsub/stanzas/event'
require 'xmpp4r/pubsub/stanzas/item'
require 'xmpp4r/pubsub/stanzas/items'
require 'xmpp4r/pubsub/stanzas/subscription'
require 'xmpp4r/pubsub/stanzas/unsubscribe'
require 'xmpp4r/dataforms'

module Jabber
  module PubSub
    ##
    # A Helper representing a PubSub Service
    class ServiceHelper

      ##
      # Creates a new representation of a pubsub service
      # stream:: [Jabber::Stream]
      # pubsubjid:: [String] or [Jabber::JID]
      def initialize(stream, pubsubjid)
        @stream = stream
        @pubsubjid = pubsubjid
        @event_cbs = CallbackList.new
        @stream.add_message_callback(200,self) { |message|
          handle_message(message)
        }
      end
      
      ##
      # get all subscriptions on a pubsub component
      # return:: [Hash] of [PubSub::Subscription]
      def get_subscriptions_from_all_nodes
        iq = basic_pubsub_query(:get)
        entities = iq.pubsub.add(REXML::Element.new('subscriptions'))
        res = nil
        @stream.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('subscriptions')
            res = []
            reply.pubsub.first_element('subscriptions').each_element('subscription') { |subscription|
    	        res << Jabber::PubSub::Subscription.import(subscription)
             } 
          end
          true
        }

        res
      end
      ##
      # subscribe to a node
      # node:: [String]
      # return:: [Hash] of { attributename => value }
      def subscribe_to(node)
        iq = basic_pubsub_query(:set)
        sub = REXML::Element.new('subscribe')
        sub.attributes['node'] = node
        sub.attributes['jid'] = @stream.jid.strip.to_s
        iq.pubsub.add(sub)
        res = nil
        @stream.send_with_id(iq) do |reply|
          pubsubanswer = reply.pubsub
          if pubsubanswer.first_element('subscription')
            res = PubSub::Subscription.import(pubsubanswer.first_element('subscription'))
          end
          true
        end # @stream.send_with_id(iq)
        res
      end

      ##
      # Unsubscibe from a node with an optional subscription id
      #
      # May raise ErrorException
      # node:: [String]
      # subid:: [String] or nil
      # return:: true
      def unsubscribe_from(node,subid=nil)
        iq = basic_pubsub_query(:set)
	unsub = PubSub::Unsubscribe.new
	unsub.node = node
	unsub.jid = @stream.jid.strip
        iq.pubsub.add(unsub)
        ret = false
        @stream.send_with_id(iq) { |reply| 
        
          unsubscribe = PubSub::Unsubscribe.import(reply.pubsub.first_element('unsubscribe'))
          if unsubscribe.jid == @stream.jid.strip && unsubscribe.node == node 
            ret = true
          end
          true 
        } # @stream.send_with_id(iq)
        ret
      end
      
      
      
      
      
      ##
      # gets all items from a pubsub node
      # node:: [String]
      # count:: [Fixnum]
      # return:: [Hash] { id => [Jabber::PubSub::Item] }
      def get_items_from(node,count=nil)
        iq = basic_pubsub_query(:get)
        items = Jabber::PubSub::Items.new
        items.node = node
        iq.pubsub.add(items)
        res = nil
        @stream.send_with_id(iq) { |reply|
          if reply.kind_of?(Iq) and reply.pubsub and reply.pubsub.first_element('items')
            res = {}
            reply.pubsub.first_element('items').each_element('item') do |item|
              res[item.attributes['id']] = item.children.first if item.children.first
            end
          end
          true
        }
        res
      end

      ##
      # NOTE: this method sends only one item per publish request because some services may not
      # allow batch processing
      # maybe this will changed in the future
      # node:: [String]
      # item:: [Jabber::PubSub::Item]
      # return:: true
      # it automaticly generates a id for the item 
      def publish_item_to(node,item)
        iq = basic_pubsub_query(:set)
	publish = iq.pubsub.add(REXML::Element.new('publish'))
        publish.attributes['node'] = node
        
        if item.kind_of?(Jabber::PubSub::Item)
    	  item.id = Jabber::IdGenerator.generate_id
          publish.add(item)
          @stream.send_with_id(iq) { |reply| true }
        end
      end

      ##
      # node:: [String]
      # item:: [REXML::Element]
      # id:: [String]
      # return:: true
      def publish_item_with_id_to(node,item,id)
        iq = basic_pubsub_query(:set)
        publish = iq.pubsub.add(REXML::Element.new('publish'))
        publish.attributes['node'] = node
          
        if item.kind_of?(REXML::Element)
          xmlitem = Jabber::PubSub::Item.new
          xmlitem.id = id
          xmlitem.import(item)
          publish.add(xmlitem)
        else
          raise "given item is not a proper xml document or Jabber::PubSub::Item"
        end
        @stream.send_with_id(iq) { |reply| true }
      end

      ##
      # purges all items on a persist node
      # node:: [String]
      # return:: true
      def purge_items_from(node)
        iq = basic_pubsub_query(:set)
	purge = REXML::Element.new('purge')
	purge.attributes['node'] = node
	iq.pubsub.add(purge)
	@stream.send_with_id(iq) { |reply| true }
      end

      ##
      # Create a new node on the pubsub service
      # node:: [String] you node name - otherwise you get a automaticly generated one (in most cases)
      # configure:: [Jabber::XMLStanza] if you want to configure you node (default nil)
      # return:: [String]
      def create_node(node=nil, configure=nil)
        rnode = nil
        iq = basic_pubsub_query(:set)
        iq.pubsub.add(REXML::Element.new('create')).attributes['node'] = node
        if configure
          confele =  REXML::Element.new('configure')

          if configure.type_of?(XMLStanza)
            confele << configure
          end
          iq.pubsub.add(confele)
        end

        @stream.send_with_id(iq) do |reply|
          if (create = reply.first_element('pubsub/create'))
            rnode = create.attributes['node']
          end
          true
        end

        rnode
      end

      ##
      # Delete a pubsub node
      # node:: [String]
      # return:: true
      def delete_node(node)
        iq = basic_pubsub_query(:set,true)
        iq.pubsub.add(REXML::Element.new('delete')).attributes['node'] = node
        @stream.send_with_id(iq) { |reply|
          true
        }
      end


      ##
      # shows the affiliations on a pubsub service
      # node:: [String]
      # return:: [Hash] of { node => symbol }
      def get_affiliations(node = nil)
        iq = basic_pubsub_query(:get)
        affiliations = iq.pubsub.add(REXML::Element.new('affiliations'))
	affiliations.attributes['node'] = node
        res = nil
        @stream.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('affiliations')
            res = {}
            reply.pubsub.first_element('affiliations').each_element('affiliation') do |affiliation|
              # TODO: This should be handled by an affiliation element class
              aff = case affiliation.attributes['affiliation']
                      when 'owner' then :owner
                      when 'publisher' then :publisher
                      when 'none' then :none
                      when 'outcast' then :outcast
                      else nil
                    end
              res[affiliation.attributes['node']] = aff
            end
          end
          true
        }
        res
      end

      ##
      # shows all subscriptions on the given node
      # node:: [String]
      # return:: [Array] of [Jabber::Pubsub::Subscription]
      def get_subscriptions_from(node)
        iq = basic_pubsub_query(:get)
        entities = iq.pubsub.add(REXML::Element.new('subscriptions'))
        entities.attributes['node'] = node
        res = nil
        @stream.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('subscriptions')
            res = []
	    if reply.pubsub.first_element('subscriptions').attributes['node'] == node
              reply.pubsub.first_element('subscriptions').each_element('subscription') { |subscription|
    	        res << PubSub::Subscription.import(subscription)
              } 
	    end
          end
          true
        }
        res
      end

      ##
      # shows all jids of subscribers of a node
      # node:: [String]
      # return:: [Array] of [String]
      def get_subscribers_from(node)
        res = []
        get_subscriptions_from(node).each { |sub|
	 
          res << sub.jid
        }
        res
      end


      ##
      # get options from a node
      # node:: [String]
      # subid:: [String] or nil
      # return:: [Jabber::XData]
      def get_options_from(node,subid=nil)
        iq = basic_pubsub_query(:get)
        opt = REXML::Element.new('options')
        opt.attributes['node'] = node
        opt.attributes['jid'] = @stream.jid.strip
        opt.attributes['subid'] = subid
        iq.pubsub.add(opt)
        ret = nil
        @stream.send_with_id(iq) { |reply|
          reply.pubsub.options.first_element('x') { |xdata|
    
            ret = xdata if xdata.kind_of?(Jabber::XData)
    
          }
        true
        }
        return ret
      end

      ##
      # set options for a node
      # node:: [String]
      # options:: [Jabber::XData]
      # subid:: [String] or nil
      # return:: true 
      def set_options_for(node,options,subid=nil)
        iq = basic_pubsub_query(:set)
        opt = REXML::Element.new('options')
        opt.attributes['node'] = node
        opt.attributes['jid'] = @stream.jid.strip
        opt.attributes['subid'] = subid
        iq.pubsub.add(opt)
        iq.pubsub.options.add(options)
        @stream.send_with_id(iq) { |reply| true }
      end
      

      ##
      # String representation
      # result:: [String] The PubSub service's JID
      def to_s
        @pubsubjid.to_s
      end

      ##
      # Register callbacks for incoming events
      # (i.e. Message stanzas containing) PubSub notifications
      def add_event_callback(prio = 200, ref = nil, &block)
        @event_cbs.add(prio, ref, block)
      end

      private

      ##
      # creates a basic pubsub iq
      # basic_pubsub_query(type)
      # type:: [Symbol]
      def basic_pubsub_query(type,ownerusecase = false)
        iq = Jabber::Iq::new(type,@pubsubjid)
	if ownerusecase 
	  iq.add(IqPubSubOwner.new)
	else
          iq.add(IqPubSub.new)
	end
        iq.from = @stream.jid.strip
	iq
      end

      ##
      # handling incoming events
      # handle_message(message)
      # message:: [Jabber::Message]
      def handle_message(message)
        if message.from == @pubsubjid and message.first_element('event').kind_of?(Jabber::PubSub::Event)
          event = message.first_element('event')
          @event_cbs.process(event)
        end
      end

    end
  end
end
