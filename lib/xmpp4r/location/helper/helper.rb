# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r'
require 'xmpp4r/pubsub'
require 'xmpp4r/location/location'

module Jabber
  module UserLocation
    ##
    # A Helper for XEP-0080 User Location
    #
    # Use this helper to send a user's location, or receive them from a
    # specified jid. Described at http://www.xmpp.org/extensions/xep-0080.html
    #
    # For example:
    # <pre>
    # h = UserLocation::Helper( @client, 'radio1@hug.hellomatty.com' )
    # h.add_userlocation_callback do |location|
    #   puts "Now in: #{location.locality}"
    # end
    # </pre>
    class Helper < PubSub::ServiceHelper
      ##
      # Send out the current location.
      #
      # location:: [Jabber::UserLocation::Location] current_location
      def current_location(location)
        item = Jabber::PubSub::Item.new()
        item.add(location)

        publish_item_to(NS_USERLOCATION, item)
      end

      ##
      # Use this method to indicate that you wish to stop publishing
      # a location.
      def stop_publishing
        current_location(Jabber::UserLocation::Location.new())
      end

      ##
      # Add a callback that will be invoked when a location is received
      # from the jid specified when you constructed the Helper.
      def add_userlocation_callback(prio = 200, ref = nil, &block)
        add_event_callback(prio, ref) do |event|
          location = event.first_element('items/item/location')
          if location
            block.call(location)
          end
        end
      end
    end
  end
end
