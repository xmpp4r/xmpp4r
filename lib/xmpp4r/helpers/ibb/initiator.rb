module Jabber
  module Helpers
    ##
    # Implementation of IBB at the initiator side
    class IBBInitiator < IBB
      ##
      # Open the stream to the peer,
      # waits for successful result
      #
      # May throw ErrorException
      def open
        iq = Iq.new(:set, @peer_jid)
        open = iq.add REXML::Element.new('open')
        open.add_namespace IBB::NS_IBB
        open.attributes['sid'] = @session_id
        open.attributes['block-size'] = @block_size

        @stream.send_with_id(iq) { |answer|
          answer.type == :result
        }

        activate
      end
    end
  end
end

