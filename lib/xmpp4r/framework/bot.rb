require 'xmpp4r/framework/base'

require 'xmpp4r/roster'

module Jabber
  module Framework
    class Bot < Base
      helper :roster, Jabber::Roster::Helper

      def initialize(jid, password)
        cl = Jabber::Client::new(jid)
        cl.connect
        cl.auth(password)

        super(cl)

        # Required helpers
        roster

        @presence_show = nil
        @presence_status = nil
      end

      def set_presence(show=nil, status=nil)
        @presence_show = show
        @presence_status = status
        send_presence
      end

      private

      def send_presence
        roster.wait_for_roster

        # TODO: vcard photo hash
        presence = Jabber::Presence.new(@presence_show, @presence_status)
        #presence.add
        @stream.send(presence)
      end
    end

  end
end
