# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/x'
require 'xmpp4r/jid'
require 'xmpp4r/x/mucuseritem'

module Jabber
  ##
  # Class for <x/> elements
  # with namespace http://jabber.org/protocol/muc
  #
  # See JEP-0058 for details
  class XMuc < X
    ##
    # Initialize an <x/> element
    # and set namespace to http://jabber.org/protocol/muc
    def initialize
      super
      add_namespace('http://jabber.org/protocol/muc')
    end
  end

  ##
  # Class for <x/> elements
  # with namespace http://jabber.org/protocol/muc#user
  #
  # See JEP-0058 for details
  class XMucUser < X
    ##
    # Initialize an <x/> element
    # and set namespace to http://jabber.org/protocol/muc#user
    def initialize
      super
      add_namespace('http://jabber.org/protocol/muc#user')
    end

    ##
    # Add a children element,
    # will be imported to [XMucUserItem] if name is "item"
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
