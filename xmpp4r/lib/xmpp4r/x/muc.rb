# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/x'
require 'xmpp4r/jid'
require 'xmpp4r/x/mucuseritem'

module Jabber
  class XMuc < X
    def initialize
      super
      add_namespace('http://jabber.org/protocol/muc')
    end
  end

  class XMucUser < X
    def initialize
      super
      add_namespace('http://jabber.org/protocol/muc#user')
    end

    def add(element)
      if element.kind_of?(REXML::Element) && (element.name == 'item')
        super(XMucUserItem::new.import(element))
      else
        super(element)
      end
    end
  end

  X.add_namespaceclass('http://jabber.org/protocol/muc', XMuc)
  X.add_namespaceclass('http://jabber.org/protocol/muc#user', XMucUser)
end
