# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'

module Jabber
  module Helpers
    ##
    # The Vcard helper retrieves vCards
    class Vcard
      ##
      # Initialize a new Vcard helper
      def initialize(stream)
        @stream = stream
      end

      ##
      # Retrieve vCard of the RosterItem
      # (Resource should be stripped before!)
      #
      # Raises exception upon retrieval error
      #
      # Usage of Threads is suggested here as vCards can be very
      # big (see <tt>/iq/vCard/PHOTO/BINVAL</tt>).
      # result:: [Jabber::IqVcard] or [Jabber::Error]
      #
      # TODO: Add some id generation here - some servers send
      # empty <iq type='result' .../> stanzas. :-(
      def get(jid)
        res = nil
        request = Iq.new(:get, jid)
        request.add(IqVcard.new)
        @stream.send(request) { |answer|
          if answer.kind_of?(Iq) and answer.from == jid
            if answer.type == :result
              res = answer.vcard
              true
            elsif answer.type == :error
              res = answer.first_element('error')
              true
            else
              false
            end
          else
            false
          end
        }
        if res.kind_of?(Error)
          raise "Error getting vCard: #{res.error}, #{res.text}"
        elsif !res.kind_of?(IqVcard)
          raise "Unspecified error getting vCard"
        end
        res
      end
    end
  end
end

