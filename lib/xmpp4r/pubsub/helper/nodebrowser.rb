# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/discovery'

module Jabber
  module PubSub
    class NodeBrowser
      ##
      # Initialize a new NodeBrowser
      # new(stream,pubsubservice)
      # strem:: [Jabber::Stream]
      def initialize(stream)
        @stream = stream
      end

      ##
      # Retrive the name of a PubSub Service
      # Throws an ErrorException when receiving
      # <tt><iq type='error'/></tt>
      # jid:: [JID] Target entity (set only domain!)
      # return:: [String] or [nil]

      def nodes(jid)
        iq = Iq.new(:get,jid)
        iq.from = @stream.jid
        iq.add(Discovery::IqQueryDiscoItems.new)
        nodes = []
        err = nil
        @stream.send_with_id(iq) { |answer|
          if answer.type == :result
            answer.query.each_element('item') { |item|
              nodes.push(item.node)
            }
            true
          elsif answer.type == :error
            err = answer.error
            true
          else
            false
          end
        }
        return nodes
      end
    end
  end
end
