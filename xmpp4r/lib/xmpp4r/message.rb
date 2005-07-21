#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

require 'xmpp4r/xmlstanza'

module Jabber
  ##
  # The Message class manages the <message/> stanzas
  class Message < XMLStanza

    ##
    # Create a new message
    def initialize(to = nil, body = nil)
      super("message")
      if not to.nil?
        set_to(to)
      end
      if !body.nil?
        add_element(XMLElement::new("body").add_text(body))
      end
    end

    ##
    # Returns the message's body, or nil
    def body
      s = nil
      each_element('body') { |e| s = e.text if s.nil? }
      s
    end

    ##
    # Create a new message from a stanza
    def Message.import(xmlstanza)
      Message::new.import(xmlstanza)
    end

    ##
    # sets the message's body
    #
    # b:: [String] body to set
    def body=(b)
      set_body(b)
    end

    ##
    # sets the message's body
    #
    # b:: [String] body to set
    # return:: [Jabber::Protocol::XMLElement] self for chaining
    def set_body(b)
      xe = nil
      each_element('body') { |c| xe = c if xe.nil? }
      if xe.nil?
        xe = XMLElement::new('body')
        add_element(xe)
      end
      xe.text = b
      self
    end

    ##
    # sets the message's subject
    #
    # s:: [String] subject to set
    def subject=(s)
      set_subject(s)
    end

    ##
    # sets the message's subject
    #
    # s:: [String] subject to set
    # return:: [Jabber::Protocol::XMLElement] self for chaining
    def set_subject(s)
      xe = nil
      each_element('subject') { |c| xe = c if xe.nil? }
      if xe.nil?
        xe = XMLElement::new('subject')
        add_element(xe)
      end
      xe.text = s
      self
    end

    ##
    # Returns the message's subject, or nil
    def subject
      s = nil
      each_element('subject') { |e| s = e.text if s.nil? }
      s
    end
  end
end
