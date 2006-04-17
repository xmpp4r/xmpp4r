# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

module Jabber
  module MUC
    ##
    # Class for <x/> elements
    # with namespace http://jabber.org/protocol/muc
    #
    # See JEP-0045 for details
    class XMuc < X
      ##
      # Initialize an <x/> element
      # and set namespace to http://jabber.org/protocol/muc
      def initialize
        super
        add_namespace('http://jabber.org/protocol/muc')
      end

      ##
      # Text content of the <tt><password/></tt> element
      def password
        first_element_text('password')
      end

      ##
      # Set the password for joining a room
      # (text content of the <tt><password/></tt> element)
      def password=(s)
        if s
          replace_element_text('password', s)
        else
          delete_elements('password')
        end
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
      def typed_add(element)
        if element.kind_of?(REXML::Element) && (element.name == 'item')
          super(XMucUserItem::new.import(element))
        elsif element.kind_of?(REXML::Element) && (element.name == 'invite')
          super(XMucUserInvite::new.import(element))
        else
          super(element)
        end
      end

      ##
      # Retrieve the three-digit code in
      # <tt><x xmlns='http://jabber.org/protocol/muc#user'><status code='...'/></x></tt>
      # result:: [Fixnum] or nil
      def status_code
        e = nil
        each_element('status') { |xe| e = xe }
        if e and e.attributes['code'].size == 3 and e.attributes['code'].to_i != 0
          e.attributes['code'].to_i
        else
          nil
        end
      end

      ##
      # Get all <item/> elements
      # result:: [Array] of [XMucUserItem]
      def items
        res = []
        each_element('item') { |item|
          res << item
        }
        res
      end
    end

    X.add_namespaceclass('http://jabber.org/protocol/muc', XMuc)
    X.add_namespaceclass('http://jabber.org/protocol/muc#user', XMucUser)
  end
end
