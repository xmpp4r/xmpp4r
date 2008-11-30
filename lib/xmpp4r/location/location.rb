# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'time'
require 'xmpp4r/xmppelement'
require 'rexml/element'

module Jabber
  module UserLocation
    NS_USERLOCATION = 'http://jabber.org/protocol/geoloc'
    ALLOWABLE_ATTRIBUTES = %w(accuracy alt area bearing building country
      datum description floor lat locality lon postalcode region room
      speed street text timestamp uri)

    ##
    # The <geoloc> XMPP element, as defined in XEP-0080 User Location
    #
    # See http://xmpp.org/extensions/xep-0080.html - this element
    # encapsulates data about a user's current location. These are
    # expressed as child elements such as <locality>, <lat>, etc.
    # which are also managed by this class.
    #
    # If the element has no children then it indicates that the user
    # has stopped publishing their location.
    class Location < XMPPElement
      name_xmlns 'geoloc', NS_USERLOCATION
      force_xmlns true

      ##
      # Construct a new <location> element.
      #
      # Supply no arguments to make an empty element to indicate that
      # location is no longer being published.
      #
      # attributes:: [Hash] location attributes
      def initialize(attributes = {})
        super()

        # validate attributes
        attributes = attributes.select do |k,v|
          ALLOWABLE_ATTRIBUTES.include?(k) && !v.nil?
        end

        attributes.each do |k,v|
          v = x.xmlschema if v.is_a?(Time)
          add_element(REXML::Element.new(k)).text = v.to_s
        end
      end


      ##
      # Returns true if a location is currently being published, otherwise false.
      def published?
        (elements.size > 0)
      end

      ##
      # Get the accuracy attribute of this location.
      def accuracy
        first_element('accuracy').text if first_element('accuracy')
      end

      ##
      # Get the alt attribute of this location.
      def alt
        first_element('alt').text if first_element('alt')
      end

      ##
      # Get the area attribute of this location.
      def area
        first_element('area').text if first_element('area')
      end

      ##
      # Get the bearing attribute of this location.
      def bearing
        first_element('bearing').text if first_element('bearing')
      end

      ##
      # Get the building attribute of this location.
      def building
        first_element('building').text if first_element('building')
      end

      ##
      # Get the country attribute of this location.
      def country
        first_element('country').text if first_element('country')
      end

      ##
      # Get the datum attribute of this location.
      def datum
        first_element('datum').text if first_element('datum')
      end

      ##
      # Get the description attribute of this location.
      def description
        first_element('description').text if first_element('description')
      end

      ##
      # Get the floor attribute of this location.
      def floor
        first_element('floor').text if first_element('floor')
      end

      ##
      # Get the lat attribute of this location.
      def lat
        first_element('lat').text if first_element('lat')
      end

      ##
      # Get the locality attribute of this location.
      def locality
        first_element('locality').text if first_element('locality')
      end

      ##
      # Get the lon attribute of this location.
      def lon
        first_element('lon').text if first_element('lon')
      end

      ##
      # Get the postalcode attribute of this location.
      def postalcode
        first_element('postalcode').text if first_element('postalcode')
      end

      ##
      # Get the region attribute of this location.
      def region
        first_element('region').text if first_element('region')
      end

      ##
      # Get the room attribute of this location.
      def room
        first_element('room').text if first_element('room')
      end

      ##
      # Get the speed attribute of this location.
      def speed
        first_element('speed').text if first_element('speed')
      end

      ##
      # Get the street attribute of this location.
      def street
        first_element('street').text if first_element('street')
      end

      ##
      # Get the text attribute of this location.
      def text
        first_element('text').text if first_element('text')
      end

      ##
      # Get the timestamp attribute of this location.
      def timestamp
        first_element('timestamp').text if first_element('timestamp')
      end

      ##
      # Get the uri attribute of this location.
      def uri
        first_element('uri').text if first_element('uri')
      end
    end
  end
end
