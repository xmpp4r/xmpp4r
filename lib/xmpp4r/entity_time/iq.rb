# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://xmpp4r.github.io

require 'time'

module Jabber::EntityTime
  NS_TIME = 'urn:xmpp:time'

  class IqTime < Jabber::IqQuery
    name_xmlns 'time', NS_TIME

    def initialize(time=nil)
      super()
      set_time(time)
    end

    def set_time(time=nil)
      time ||= Time.now

      tzo = self.add_element('tzo')
      tzo.add_text(time_zone_offset(time))

      utc = self.add_element('utc')
      utc.add_text(utc_time(time))
    end

    private
    def utc_time(time)
      raise ArgumentError, 'invalid time object' unless time.respond_to?(:utc)
      time.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
    end

    def time_zone_offset(time)
      raise ArgumentError, 'invalid time object' unless time.respond_to?(:utc_offset)

      sec_offset = time.utc_offset
      h_offset = sec_offset.to_i / 3600
      m_offset = sec_offset.abs % 60

      "%+03d:%02d"%[h_offset, m_offset]
    end

  end # /IqTime
end # /Jabber::EntityTime
