module Jabber
  module PubSub
    # PubSub service helper for use with OAuth-authenticated nodes
    class OAuthServiceHelper < ServiceHelper
      def initialize(stream, pubsubjid)
        super(stream, pubsubjid)
      end

      # override #get_subscriptions_from_all_nodes to add an oauth element
      def get_subscriptions_from_all_nodes(oauth_consumer, oauth_token)
        iq = basic_pubsub_query(:get)

        iq.pubsub.add(create_oauth_node(oauth_consumer, oauth_token))

        entities = iq.pubsub.add(REXML::Element.new('subscriptions'))
        res = nil
        @stream.send_with_id(iq) { |reply|
          if reply.pubsub.first_element('subscriptions')
            res = []
            reply.pubsub.first_element('subscriptions').each_element('subscription') { |subscription|
              res << Jabber::PubSub::Subscription.import(subscription)
            }
          end
        }

        res
      end

      # override #subscribe_to to add an oauth element
      def subscribe_to(node, oauth_consumer, oauth_token)
        iq = basic_pubsub_query(:set)
        sub = REXML::Element.new('subscribe')
        sub.attributes['node'] = node
        sub.attributes['jid'] = @stream.jid.strip.to_s

        sub.add(create_oauth_node(oauth_consumer, oauth_token))

        iq.pubsub.add(sub)
        res = nil
        @stream.send_with_id(iq) do |reply|
          pubsubanswer = reply.pubsub
          if pubsubanswer.first_element('subscription')
            res = PubSub::Subscription.import(pubsubanswer.first_element('subscription'))
          end
        end # @stream.send_with_id(iq)
        res
      end

      # override #unsubscribe_from to add an oauth element
      def unsubscribe_from(node, oauth_consumer, oauth_token, subid=nil)
        iq = basic_pubsub_query(:set)
        unsub = PubSub::Unsubscribe.new
        unsub.node = node
        unsub.jid = @stream.jid.strip

        unsub.add(create_oauth_node(oauth_consumer, oauth_token))

        iq.pubsub.add(unsub)
        ret = false
        @stream.send_with_id(iq) { |reply|
          ret = reply.kind_of?(Jabber::Iq) and reply.type == :result
        } # @stream.send_with_id(iq)
        ret
      end

    protected

      # add the OAuth sauce (XEP-235)
      def create_oauth_node(oauth_consumer, oauth_token)
        require 'oauth/signature/hmac/sha1'
        require 'cgi'

        request = OAuth::RequestProxy.proxy \
          "method" => "iq",
          "uri"    => [@stream.jid.strip.to_s, @pubsubjid.strip.to_s] * "&",
          "parameters" => {
            "oauth_consumer_key"     => oauth_consumer.key,
            "oauth_token"            => oauth_token.token,
            "oauth_signature_method" => "HMAC-SHA1"
          }

        signature = OAuth::Signature.sign(request, :consumer => oauth_consumer, :token => oauth_token)

        oauth = REXML::Element.new("oauth")
        oauth.attributes['xmlns'] = 'urn:xmpp:oauth'

        oauth_consumer_key = REXML::Element.new("oauth_consumer_key")
        oauth_consumer_key.text = oauth_consumer.key
        oauth.add(oauth_consumer_key)

        oauth_token_node = REXML::Element.new("oauth_token")
        oauth_token_node.text = oauth_token.token
        oauth.add(oauth_token_node)

        oauth_signature_method = REXML::Element.new("oauth_signature_method")
        oauth_signature_method.text = "HMAC-SHA1"
        oauth.add(oauth_signature_method)

        oauth_signature = REXML::Element.new("oauth_signature")
        oauth_signature.text = signature
        oauth.add(oauth_signature)

        oauth
      end
    end
  end
end
