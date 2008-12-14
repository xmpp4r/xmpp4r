# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/query'

module Jabber
  module LastActivity
    NS_LAST_ACTIVITY = 'jabber:iq:last'

    ##
    # Class for handling Last Activity queries
    # (XEP-0012)
    class IqQueryLastActivity < IqQuery
      name_xmlns 'query', NS_LAST_ACTIVITY

      ##
      # Get the number of seconds since last activity.
      #
      # With a bare jid, this will return the number of seconds since the
      # client was last seen (offline user query).
      #
      # With a full jid, this will return the number of seconds that the
      # client has been idle (online user query).
      #
      # With a server, this will return the server or component's uptime in
      # seconds (server / component query).
      def seconds
        attributes['seconds'] ? attributes['seconds'].to_i : nil
      end

      ##
      # Set the number of seconds since last activity
      def seconds=(val)
        attributes['seconds'] = val.to_s
      end

      ##
      # Set the number of seconds since last activity
      # (chaining-friendly)
      def set_second(val)
        self.seconds = val
        self
      end

      ##
      # For an offline user query, get the last status.
      def status
        self.text
      end

      ##
      # For an offline user query, set the last status.
      def status=(val)
        self.text = val
      end

      ##
      # For an offline user query, set the last status.
      # (chaining-friendly)
      def set_status(val)
        self.status = val
        self
      end
    end
  end
end
