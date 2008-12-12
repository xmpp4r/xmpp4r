# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r'
require 'xmpp4r/last'

module Jabber
  module LastActivity
    ##
    # A Helper to manage discovery of Last Activity.
    class Helper
      def initialize(client)
        @stream = client
      end

      ##
      # Gets the last activity from a JID.
      # jid:: [JID]
      # return:: [Jabber::LastActivity::IqQueryLastActivity]
      def get_last_activity_from(jid)
        iq = Jabber::Iq.new(:get, jid)
        iq.from = @stream.jid
        iq.add(Jabber::LastActivity::IqQueryLastActivity.new)

        reply = @stream.send_with_id(iq)

        if reply.query && reply.query.kind_of?(IqQueryLastActivity)
          reply.query
        else
          nil
        end
      end

    end
  end
end
