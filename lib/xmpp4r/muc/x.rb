#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

#require 'time'

require 'xmpp4r/x'
require 'xmpp4r/jid'
require 'xmpp4r/muc/xmucuseritem'

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

    def add(xmlelement)
      if xmlelement.kind_of?(XMLElement) && (xmlelement.name == 'item')
        super(XMucUserItem::new.import(xmlelement))
      else
        super(xmlelement)
      end
    end
  end

  X.add_namespace('http://jabber.org/protocol/muc', XMuc)
  X.add_namespace('http://jabber.org/protocol/muc#user', XMucUser)
end
