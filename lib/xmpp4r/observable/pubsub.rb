# =XMPP4R - XMPP Library for Ruby
#
# This file's copyright (c) 2009 by Pablo Lorenzzoni <pablo@propus.com.br>
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io

require 'xmpp4r/pubsub'
require 'xmpp4r/pubsub/helper/servicehelper'
require 'xmpp4r/pubsub/helper/nodebrowser'
require 'xmpp4r/pubsub/helper/nodehelper'

module Jabber
class Observable
  # Jabber::Observable::PubSub - Convenience subclass to deal with PubSub
  class PubSub
    class NoService < StandardError; end #:nodoc:

    class AlreadySet < StandardError; end #:nodoc:

    # Creates a new PubSub object
    #
    # observable:: points a Jabber::Observable object
    def initialize(observable)
      @observable = observable

      @helper = @service_jid = nil
      @disco = Jabber::Discovery::Helper.new(@observable.client)
      attach!
    end

    def attach!
      begin
        domain = Jabber::JID.new(@observable.jid).domain
        @service_jid = "pubsub." + domain
        set_service(@service_jid)
      rescue
        @helper = @service_jid = nil
      end
      return has_service?
    end

    def inspect  #:nodoc:
      if has_service?
        sprintf("#<%s:0x%x @service_jid=%s>", self.class.name, __id__, @service_jid)
      else
        sprintf("#<%s:0x%x @has_service?=false>", self.class.name, __id__)
      end
    end

    # Checks if the PubSub service is set
    def has_service?
      ! @helper.nil?
    end

    # Sets the PubSub service. Just one service is allowed. If nil, reset.
    def set_service(service)
      if service.nil?
        @helper = @service_jid = nil
      else
        raise NotConnected, "You are not connected" if ! @observable.connected?
        raise AlreadySet, "You already have a PubSub service (#{@service_jid})." if has_service?
        @helper = Jabber::PubSub::ServiceHelper.new(@observable.client, service)
        @service_jid = service

        @helper.add_event_callback do |event|
          @observable.changed(:event)
          @observable.notify_observers(:event, event)
        end
      end
    end

    # Subscribe to a node.
    def subscribe_to(node)
      raise_noservice if ! has_service?
      @helper.subscribe_to(node) unless is_subscribed_to?(node)
    end

    # Unsubscribe from a node.
    def unsubscribe_from(node)
      raise_noservice if ! has_service?
      @helper.unsubscribe_from(node)
    end

    # Return the subscriptions we have in the configured PubSub service.
    def subscriptions
      raise_noservice if ! has_service?
      @helper.get_subscriptions_from_all_nodes()
    end

    # Create a PubSub node (Lots of options still have to be encoded!)
    def create_node(node)
      raise_noservice if ! has_service?
      begin
        @helper.create_node(node)
      rescue => e
        raise e
        return nil
      end
      @my_nodes << node if defined? @my_nodes
      node
    end

    # Return an array of nodes I own
    def my_nodes
      if ! defined? @my_nodes
        ret = []
        subscriptions.each do |sub|
           ret << sub.node if sub.attributes['affiliation'] == 'owner'
        end
        @my_nodes = ret
      end
      return @my_nodes
    end

    # Return true if a given node exists
    def node_exists?(node)
      ret = []
      if ! defined? @existing_nodes or ! @existing_nodes.include?(node)
        # We'll renew @existing_nodes if we haven't got it the first time
        reply = @disco.get_items_for(@service_jid)
        reply.items.each do |item|
          ret << item.node
        end
        @existing_nodes = ret
      end
      return @existing_nodes.include?(node)
    end

    # Returns an array of nodes I am subscribed to
    def subscribed_nodes
      ret = []
      subscriptions.each do |sub|
        next if sub.node.nil?
        ret << sub.node if sub.attributes['subscription'] == 'subscribed' and ! my_nodes.include?(sub.node)
      end
      return ret
    end

    # Return true if we're subscribed to that node
    def is_subscribed_to?(node)
      ret = false
      subscriptions.each do |sub|
        ret = true if sub.node == node and sub.attributes['subscription'] == 'subscribed'
      end
      return ret
    end

    # Delete a PubSub node (Lots of options still have to be encoded!)
    def delete_node(node)
      raise_noservice if ! has_service?
      begin
        @helper.delete_node(node)
      rescue => e
        raise e
        return nil
      end
      @my_nodes.delete(node) if defined? @my_nodes
      node
    end

    # Publish an Item. This infers an item of Jabber::PubSub::Item kind is passed
    def publish_item(node, item)
      raise_noservice if ! has_service?
      @helper.publish_item_to(node, item)
    end

    # Publish Simple Item. This is an item with one element and some text to it.
    def publish_simple_item(node, text)
      raise_noservice if ! has_service?

      item = Jabber::PubSub::Item.new
      xml = REXML::Element.new('value')
      xml.text = text
      item.add(xml)
      publish_item(node, item)
    end

    # Publish atom Item. This is an item with one atom entry with title, body and time.
    def publish_atom_item(node, title, body, time = Time.now)
      raise_noservice if ! has_service?

      item = Jabber::PubSub::Item.new
      entry = REXML::Element.new('entry')
      entry.add_namespace("http://www.w3.org/2005/Atom")
      mytitle = REXML::Element.new('title')
      mytitle.text = title
      entry.add(mytitle)
      mybody = REXML::Element.new('body')
      mybody.text = body
      entry.add(mybody)
      published = REXML::Element.new("published")
      published.text = time.utc.iso8601
      entry.add(published)
      item.add(entry)
      publish_item(node, item)
    end

    # Get items from a node
    def get_items_from(node, count = nil)
      raise_noservice if ! has_service?
      @helper.get_items_from(node, count)
    end

    private

    def raise_noservice #:nodoc:
      raise NoService, "Have you forgot to call #set_service ?"
    end
  end # of class PubSub
end # of class Observable
end # of module Jabber
