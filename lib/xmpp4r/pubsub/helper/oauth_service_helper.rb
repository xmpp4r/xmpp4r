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

        entities = iq.pubsub.add(REXML::Element.new('subscriptions'))
        iq.pubsub.add(create_oauth_node(oauth_consumer, oauth_token))

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

        iq.pubsub.add(sub)
        iq.pubsub.add(create_oauth_node(oauth_consumer, oauth_token))

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
      def unsubscribe_from(node, oauth_consumer, oauth_token, subid = nil)
        iq = basic_pubsub_query(:set)
        unsub = PubSub::Unsubscribe.new
        unsub.node = node
        unsub.jid = @stream.jid.strip

        iq.pubsub.add(unsub)
        iq.pubsub.add(create_oauth_node(oauth_consumer, oauth_token))

        ret = false
        @stream.send_with_id(iq) { |reply|
          ret = reply.kind_of?(Jabber::Iq) and reply.type == :result
        } # @stream.send_with_id(iq)
        ret
      end

    protected

      # add the OAuth sauce (XEP-0235)
      # The `options` hash may contain the following parameters:
      #  :oauth_nonce            => nonce (one will be generated otherwise)
      #  :oauth_timestamp        => timestamp (one will be generated otherwise)
      #  :oauth_signature_method => signature method (defaults to HMAC-SHA1)
      #  :oauth_version          => OAuth version (defaults to "1.0")
      def create_oauth_node(oauth_consumer, oauth_token, options = {})
        require 'oauth/signature/hmac/sha1'
        require 'cgi'

        request = OAuth::RequestProxy.proxy \
          "method" => "iq",
          "uri"    => [@stream.jid.strip.to_s, @pubsubjid.strip.to_s] * "&",
          "parameters" => {
            "oauth_consumer_key"     => oauth_consumer.key,
            "oauth_nonce"            => options[:oauth_nonce] || OAuth::Helper.generate_nonce,
            "oauth_timestamp"        => options[:oauth_timestamp] || OAuth::Helper.generate_timestamp,
            "oauth_token"            => oauth_token.token,
            "oauth_signature_method" => options[:oauth_signature_method] || "HMAC-SHA1",
            "oauth_version"          => options[:oauth_version] || "1.0"
          }

        request.sign!(:consumer => oauth_consumer, :token => oauth_token)

        # TODO create XMPPElements for OAuth elements
        oauth = REXML::Element.new("oauth")
        oauth.attributes['xmlns'] = 'urn:xmpp:tmp:oauth'

        oauth_consumer_key = REXML::Element.new("oauth_consumer_key")
        oauth_consumer_key.text = request.oauth_consumer_key
        oauth.add(oauth_consumer_key)

        oauth_token_node = REXML::Element.new("oauth_token")
        oauth_token_node.text = request.oauth_token
        oauth.add(oauth_token_node)

        oauth_signature_method = REXML::Element.new("oauth_signature_method")
        oauth_signature_method.text = request.oauth_signature_method
        oauth.add(oauth_signature_method)

        oauth_signature = REXML::Element.new("oauth_signature")
        oauth_signature.text = request.oauth_signature
        oauth.add(oauth_signature)

        oauth_timestamp = REXML::Element.new("oauth_timestamp")
        oauth_timestamp.text = request.oauth_timestamp
        oauth.add(oauth_timestamp)

        oauth_nonce = REXML::Element.new("oauth_nonce")
        oauth_nonce.text = request.oauth_nonce
        oauth.add(oauth_nonce)

        oauth_version = REXML::Element.new("oauth_version")
        oauth_version.text = request.oauth_version
        oauth.add(oauth_version)

        oauth
      end
    end
  end
end
