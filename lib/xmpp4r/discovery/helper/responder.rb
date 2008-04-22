# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'
require 'xmpp4r/errorexception'
require 'xmpp4r/discovery/iq/discoinfo'
require 'xmpp4r/discovery/iq/discoitems'

module Jabber
  module Discovery
    ##
    # Responds to Service Discovery queries on a given node
    #
    # Modify returned elements by these attributes:
    # * Responder#identities
    # * Responder#features (Responder#add_features is a short-cut accepting an Array of Strings, too)
    # * Responder#forms
    # * Responder#items
    class Responder
      ##
      # Service Discovery node this Responder is responsible for
      # (will not answer queries for other nodes)
      attr_reader :node

      ##
      # Identities returned on Discovery Info query
      attr_accessor :identities
      ##
      # Features returned on Discovery Info query
      attr_accessor :features
      ##
      # Forms returned on Discovery Info query
      # (such as Software Information)
      attr_accessor :forms

      ##
      # Children returned on Discovery Item query
      attr_accessor :items

      ##
      # Initialize responder for a specific node
      # stream:: [Jabber::Stream]
      # node:: [nil] or [String]
      def initialize(stream, node=nil, identities=[], features=[])
        @stream = stream
        @node = node
        @identities = identities
        @features = features
        @forms = []
        @items = []

        @stream.add_iq_callback(180, self) do |iq|
          if iq.type == :get and
             iq.query.kind_of? IqQueryDiscoInfo and
             iq.query.node == @node

            answer = iq.answer(false)
            answer.type = :true
            query = answer.add(IqQueryDiscoInfo.new)
            (@identities + @features + @forms).each do |element|
              query.add(element)
            end
            @stream.send(answer)

            true  # handled

          elsif iq.type == :get and
                iq.query.kind_of? IqQueryDiscoItems and
                iq.query.node == @node

            answer = iq.answer(false)
            answer.type = :true
            query = answer.add(IqQueryDiscoItems.new)
            @items.each do |element|
              query.add(element)
            end
            @stream.send(answer)

            true  # handled

          else
            false # not handled
          end
        end
      end

      ##
      # Add a feature
      # feature:: [Jabber::Discovery::Feature] or [String]
      def add_feature(feature)
        if feature.kind_of? Feature
          @features << feature
        else
          @features << Feature.new(feature.to_s)
        end
      end

      ##
      # Add a series of features
      # features:: Array of [Jabber::Discovery::Feature] or [String]
      def add_features(features)
        features.each { |feature|
          add_feature(feature)
        }
      end

      ##
      # Generate a XEP-0115: Entity Capabilities <c/> element
      # for inclusion in Presence stanzas. This enables efficient
      # caching of Service Discovery information.
      def generate_caps
        Caps::C.new(@node, Caps::generate_ver(@identities, @features, @forms))
      end
    end
  end
end

