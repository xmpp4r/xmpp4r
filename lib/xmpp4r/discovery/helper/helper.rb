# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r'
require 'xmpp4r/discovery'

module Jabber
  module Discovery
    ##
    # A Helper to manage service and item discovery.
    class Helper
      def initialize(client)
        @stream = client
      end

      ##
      # Service discovery on a JID.
      # jid:: [JID]
      # return:: [Jabber::Discovery::IqQueryDiscoInfo]
      def get_info_for(jid, node = nil)
        iq = Jabber::Iq.new(:get, jid)
        iq.from = @stream.jid
        disco = Jabber::Discovery::IqQueryDiscoInfo.new
        disco.node = node
        iq.add(disco)

        res = nil

        @stream.send_with_id(iq) { |reply|
          res = reply.query
        }

        res
      end

      ##
      # Item discovery on a JID.
      # jid:: [JID]
      # return:: [Jabber::Discovery::IqQueryDiscoItems]
      def get_items_for(jid, node = nil)
        iq = Jabber::Iq.new(:get, jid)
        iq.from = @stream.jid
        disco = Jabber::Discovery::IqQueryDiscoItems.new
        disco.node = node
        iq.add(disco)

        res = nil

        @stream.send_with_id(iq) { |reply|
          res = reply.query
        }

        res
      end
    end
  end
end
