module Jabber
  module PubSub
    # Jabber::Stream helper that will transparently sign PubSub requests
    module OAuthPubSubStreamHelper
      attr_accessor :pubsubjid, :oauth_consumer, :oauth_token, :oauth_options

      # enhanced #send_with_id method that signs stanzas
      def send_with_id(iq)
        if iq.first_element("pubsub")
          oauth = OAuthServiceHelper.create_oauth_node(self.jid, self.pubsubjid, self.oauth_consumer, self.oauth_token, self.oauth_options)
          iq.pubsub.add(oauth)
        end

        super(iq)
      end
    end

    # PubSub service helper for use with OAuth-authenticated nodes
    class OAuthServiceHelper < ServiceHelper
      def initialize(stream, pubsubjid, oauth_consumer, oauth_token, options = {})
        # imbue the stream with magical OAuth signing powers
        stream.extend(OAuthPubSubStreamHelper)
        stream.oauth_consumer = oauth_consumer
        stream.oauth_token = oauth_token
        stream.oauth_options = options
        stream.pubsubjid = pubsubjid

        super(stream, pubsubjid)
      end

      # add the OAuth sauce (XEP-0235)
      # The `options` hash may contain the following parameters:
      #  :oauth_nonce            => nonce (one will be generated otherwise)
      #  :oauth_timestamp        => timestamp (one will be generated otherwise)
      #  :oauth_signature_method => signature method (defaults to HMAC-SHA1)
      #  :oauth_version          => OAuth version (defaults to "1.0")
      def self.create_oauth_node(jid, pubsubjid, oauth_consumer, oauth_token, options = {})
        require 'oauth'

        request = OAuth::RequestProxy.proxy \
          "method" => "iq",
          "uri"    => [jid.strip.to_s, pubsubjid.strip.to_s] * "&",
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
        oauth.attributes['xmlns'] = 'urn:xmpp:oauth:0'

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
