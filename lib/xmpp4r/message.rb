# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/xmlstanza'
require 'xmpp4r/error'
require 'xmpp4r/x'

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
        add_element(REXML::Element::new("body").add_text(body))
      end
    end

    ##
    # Add a sub-element
    #
    # Will be converted to [Error] if named "error"
    # TODO: convert <x/>
    # xmlelement:: [REXML::Element] to add
    def add(xmlelement)
      if xmlelement.kind_of?(REXML::Element) && (xmlelement.name == 'error')
        super(Error::import(xmlelement))
      elsif xmlelement.kind_of?(REXML::Element) && (xmlelement.name == 'x')
        super(X::import(xmlelement))
      else
        super(xmlelement)
      end
    end

    ##
    # Get the type of the Message stanza
    #
    # The following Symbols are allowed:
    # * :chat
    # * :error
    # * :groupchat
    # * :headline
    # * :normal
    # result:: [Symbol] or nil
    def type
      case attributes['type']
        when 'chat' then :chat
        when 'error' then :error
        when 'groupchat' then :groupchat
        when 'headline' then :headline
        when 'normal' then :normal
        else nil
      end
    end

    ##
    # Set the type of the Message stanza (see type)
    # v:: [Symbol] or nil
    def type=(v)
      case v
        when :chat then attributes['type'] = 'chat'
        when :error then attributes['type'] = 'error'
        when :groupchat then attributes['type'] = 'groupchat'
        when :headline then attributes['type'] = 'headline'
        when :normal then attributes['type'] = 'normal'
        else attributes['type'] = nil
      end
    end

    ##
    # Set the type of the Message stanza (chaining-friendly)
    # v:: [Symbol] or nil
    def set_type(v)
      self.type = v
      self
    end

    ##
    # Get the first <x/> element of this stanza
    def x
      xe = nil
      each_element('x') { |e| xe = e }
      xe
    end

    ##
    # Returns the message's body, or nil
    def body
      return first_element_text('body')
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
    # return:: [REXML::Element] self for chaining
    def set_body(b)
      replace_element_text('body', b)
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
    # return:: [REXML::Element] self for chaining
    def set_subject(s)
      xe = first_element('subject')
      if xe.nil?
        xe = REXML::Element::new('subject')
        add_element(xe)
      end
      xe.text = s
      self
    end

    ##
    # Returns the message's subject, or nil
    def subject
      return first_element_text('subject')
    end

    ##
    # sets the message's thread
    # s:: [String] thread to set
    def thread=(s)
      delete_elements('thread')
      add_element('thread').text = s unless s.nil?
    end

    ##
    # gets the message's thread (chaining-friendly)
    # Please note that this are not [Thread] but a [String]-Identifier to track conversations
    # s:: [String] thread to set
    def set_thread(s)
      self.thread = s
      self
    end

    ##
    # Returns the message's thread, or nil
    def thread
      return first_element_text('thread')
    end
  end
end
