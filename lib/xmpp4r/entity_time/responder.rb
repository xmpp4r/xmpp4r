# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io

require 'xmpp4r/entity_time/iq'

module Jabber::EntityTime
  ##
  # XEP 202 Entity Time implementation
  #
  # @see http://xmpp.org/extensions/xep-0202.html
  #
  # @example
  # <iq type='get'
  #     from='romeo@montague.net/orchard'
  #     to='juliet@capulet.com/balcony'
  #     id='time_1'>
  #   <time xmlns='urn:xmpp:time'/>
  # </iq>
  #
  class Responder

    CALLBACK_PRIORITY = 180

    ##
    # +to_s+ allows the responder to be added to another responder as a feature
    def to_s
      NS_TIME
    end

    def initialize(stream)
      @stream = stream

      stream.add_iq_callback(CALLBACK_PRIORITY, self) do |iq|
        iq_callback(iq)
      end
    end # /initialize

    def iq_callback(iq)
      if iq.type == :get &&
          iq.first_element('time') &&
          iq.first_element('time').namespace === NS_TIME

        answer = iq.answer(false)
        answer.type = :result
        answer.add(IqTime.new(Time.now))

        @stream.send(answer)

        return true
      end

      false
    end

  end # /Responder
end # /Jabber::EntityTime
