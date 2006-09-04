module Jabber
  module PubSub
    class Helper
      def initialize(client)
        @client = client
      end

      def create(jid, node=nil)
        rnode = nil

        iq = Jabber::Iq::new(:set, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        pubsub.add(REXML::Element.new('create')).attributes['node'] = node
        @client.send_with_id(iq) { |reply|
          create = reply.first_element('pubsub/create')
          rnode = create.attributes['node'] if create
          true
        }

        rnode
      end

      def delete(jid, node)
        iq = Jabber::Iq::new(:set, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        del = pubsub.add(REXML::Element.new('delete'))
        del.attributes['node'] = node

        @client.send_with_id(iq) { |reply|
          true
        }
      end

      ##
      # items: Hash { item_id => rexml::element }
      def publish(jid, node, items)
        iq = Jabber::Iq::new(:set, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        publish = pubsub.add(REXML::Element.new('publish'))
        publish.attributes['node'] = node
        items.each { |id,element|
          item = publish.add(REXML::Element.new('item'))
          item.attributes['id'] = id
          item.add(element)
        }

        @client.send_with_id(iq) { |reply|
          true
        }
      end

      def items(jid, node)
        iq = Jabber::Iq::new(:get, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        pubsub.add(REXML::Element.new('items')).attributes['node'] = node

        res = nil
        @client.send_with_id(iq) { |reply|
          reply.each_element('/query/pubsub/items') { |items|
            res = items
          }
          true
        }
        res
      end

      def affiliations(jid)
        iq = Jabber::Iq::new(:get, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        pubsub.add(REXML::Element.new('affiliations'))

        @client.send_with_id(iq) { |reply|
          puts "affiliations reply: #{reply.to_s.inspect}"
          true
        }
        # TODO
      end

      def entities(jid, node)
        iq = Jabber::Iq::new(:get, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        entities = pubsub.add(REXML::Element.new('entities'))
        entities.attributes['node'] = node

        @client.send_with_id(iq) { |reply|
          puts "entities reply: #{reply.to_s.inspect}"
          true
        }
        # TODO
      end

      def subscribers(jid, node)
        iq = Jabber::Iq::new(:get, jid)
        pubsub = iq.add(REXML::Element.new('pubsub'))
        pubsub.add_namespace('http://jabber.org/protocol/pubsub')
        sub = pubsub.add(REXML::Element.new('subscriptions'))
        sub.attributes['node'] = node

        res = []
        @client.send_with_id(iq) { |reply|
          reply.each_element('pubsub') { |pubsub|
            pubsub.each_element('subscriptions') { |s1|
              s1.each_element('subscription') { |s2|
                res << s2.attributes['jid']
              }
            }
          }
          true
        }
        res
      end
    end
  end
end
