# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

module Jabber
  class XMucUserInvite < REXML::Element
    def initialize(to=nil, reason=nil)
      super('invite')
      set_to(to)
      set_reason(reason)
    end

    def to
      attributes['to'].nil ? nil : JID::new(attributes['to'])
    end

    def to=(j)
      attributes['to'] = j.nil? ? nil : j.to_s
    end

    def set_to(j)
      self.to = j
      self
    end

    def from
      attributes['from'].nil ? nil : JID::new(attributes['from'])
    end

    def from=(j)
      attributes['from'] = j.nil? ? nil : j.from_s
    end

    def set_from(j)
      self.from = j
      self
    end

    def reason
      text = nil
      each_element('reason') { |xe| text = xe.text }
      text
    end

    def reason=(s)
      delete_elements('reasion')
      add_element('reason').text = s
    end

    def set_reason(s)
      self.reason = s
      self
    end
  end
end
