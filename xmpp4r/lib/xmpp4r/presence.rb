# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/xmlstanza'

module Jabber
  ##
  # The presence class is used to construct presence messages to 
  # send to the Jabber service.
  class Presence < XMLStanza
    ##
    # Create presence stanza
    # show:: [String] Initial Availability Status
    # status:: [String] Initial status message
    # priority:: [Fixnum] Initial priority value
    def initialize(show=nil, status=nil, priority=nil)
      super("presence")
      set_show(show)
      set_status(status)
      set_priority(priority)
    end

    ##
    # Create a new presence from a stanza
    # result:: [Presence] Imported XMLStanza
    def Presence.import(xmlstanza)
      Presence::new.import(xmlstanza)
    end

    ##
    # Get type of presence
    #
    # result:: [Symbol] or [Nil] Possible values are:
    # * :error
    # * :probe
    # * :subscribe
    # * :subscribed
    # * :unavailable
    # * :unsubscribe
    # * :unsubscribed
    # See RFC3921 - 2.2.1. for explanation.
    def type
      case super
        when 'error' then :error
        when 'probe' then :probe
        when 'subscribe' then :subscribe
        when 'subscribed' then :subscribed
        when 'unavailable' then :unavailable
        when 'unsubscribe' then :unsubscribe
        when 'unsubscribed' then :unsubscribed
        else nil
      end
    end

    ##
    # Set type of presence
    # val:: [Symbol] See type for possible subscription types
    def type=(val)
      case val
        when :error then super('error')
        when :probe then super('probe')
        when :subscribe then super('subscribe')
        when :subscribed then super('subscribed')
        when :unavailable then super('unavailable')
        when :unsubscribe then super('unsubscribe')
        when :unsubscribed then super('unsubscribed')
        else super(nil)
      end
    end

    ##
    # Set type of presence (chaining-friendly)
    def set_type(val)
      self.type = val
      self
    end

    ##
    # Get Availability Status (RFC3921 - 5.2)
    # result:: [Symbol] or [Nil] Valid values according to RFC3921:
    # * nil (Online, no <show/> element)
    # * :away
    # * :chat (Free for chat)
    # * :dnd (Do not disturb)
    # * :xa (Extended away)
    def show
      text = nil
      each_element('show') { |show| text = show.text }
      case text
        when 'away' then :away
        when 'chat' then :chat
        when 'dnd' then :dnd
        when 'xa' then :xa
        else nil
      end
    end

    ##
    # Set Availability Status
    # val:: [Symbol] or [Nil] See show for explanation
    def show=(val)
      xe = nil
      each_element('show') { |show| xe = show }
      if xe.nil?
        xe = add_element('show')
      end

      case val
        when :away then text = 'away'
        when :chat then text = 'chat'
        when :dnd then text = 'dnd'
        when :xa then text = 'xa'
        else text = nil
      end

      if text.nil?
        delete_element(xe)
      else
        xe.text = text
      end
    end

    ##
    # Set Availability Status (chaining-friendly)
    def set_show(val)
      self.show = val
      self
    end

    ##
    # Get status message
    def status
      each_element('status') { |status| return(status.text) }
      nil
    end

    ##
    # Set status message
    def status=(val)
      xe = nil
      each_element('status') { |status| xe = status }
      if xe.nil?
        xe = add_element('status')
      end
      
      if val.nil?
        delete_element(xe)
      else
        xe.text = val
      end
    end

    ##
    # Set status message (chaining-friendly)
    def set_status(val)
      self.status = val
      self
    end

    ##
    # Get presence priority
    # result:: [Integer]
    def priority
      each_element('priority') { |prio| return(prio.text.to_i) }
      nil
    end

    ##
    # Set presence priority
    # val:: [Integer] Priority value between -128 and +127
    #
    # *Warning:* negative values make you receive no subscription requests etc.
    # (RFC3921 - 2.2.2.3.)
    def priority=(val)
      xe = nil
      each_element('priority') { |prio| xe = prio }
      if xe.nil?
        xe = add_element('priority')
      end
      
      if val.nil?
        delete_element(xe)
      else
        xe.text = val.to_s
      end
    end

    ##
    # Set presence priority (chaining-friendly)
    def set_priority(val)
      self.priority = val
      self
    end
  end
end
