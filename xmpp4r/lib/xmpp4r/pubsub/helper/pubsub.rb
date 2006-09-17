require 'xmpp4r/pubsub/iq/pubsub'

module Jabber
  module PubSub
    class Helper
      def initialize(client)
        @client = client
      end

      def create(jid, node=nil)
        rnode = nil
        iq = basic_pubsub_query(:set,jid)
        iq.pubsub.add(REXML::Element.new('create')).attributes['node'] = node
        @client.send_with_id(iq) { |reply|
          if (create = reply.first_element('pubsub/create'))
            rnode = create.attributes['node']
          end
          true
        }

        rnode
      end

      def delete(jid, node)
        iq = basic_pubsub_query(:set,jid)
        iq.pubsub.add(REXML::Element.new('delete')).attributes['node'] = node

        @client.send_with_id(iq) { |reply|
          true
        }
      end

      ##
      # items: Hash { item_id => rexml::element }
      def publish(jid, node, items)
        iq = basic_pubsub_query(:set,jid)
        publish = iq.pubsub.add(REXML::Element.new('publish'))
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
        iq = basic_pubsub_query(:get,jid)
        iq.pubsub.add(REXML::Element.new('items')).attributes['node'] = node

        res = nil
        @client.send_with_id(iq) { |reply|
          if reply.kind_of? Iq and reply.pubsub and reply.pubsub.first_element('items')
            res = {}
            reply.pubsub.first_element('items').each_element('item') do |item|
              res[item.attributes['id']] = item.children.first if item.children.first
            end
          end
          true
        }
        res
      end

      def affiliations(jid)
        iq = basic_pubsub_query(:get,jid)
        iq.pubsub.add(REXML::Element.new('affiliations'))

        res = nil
        @client.send_with_id(iq) { |reply|
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

      def subscriptions(jid, node)
        iq = basic_pubsub_query(:get, jid)
        entities = iq.pubsub.add(REXML::Element.new('subscriptions'))
        entities.attributes['node'] = node

        res = nil
        @client.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('subscriptions')
            res = []
            reply.pubsub.first_element('subscriptions').each_element('subscription') do |subscription|
              res << subscription
            end
          end

          true
        }
        res
      end

      def subscribers(jid, node)
        iq = basic_pubsub_query(:get,jid)
        sub = iq.pubsub.add(REXML::Element.new('subscriptions'))
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

      private

      def basic_pubsub_query(type, jid)
        iq = Jabber::Iq::new(type, jid)
        iq.add(IqPubSub.new)
        iq
      end
    end
  end
end
