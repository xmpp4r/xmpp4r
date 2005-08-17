#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

require 'xmpp4r/xmlstanza'

module Jabber
  ##
  # The presence class is used to construct presence messages to 
  # send to the Jabber service.
  #
  # Note that the 'type' attribute is valid for this stanza too and
  # is handled by the XMLStanza class. Valid strings are:
  # * error
  # * probe
  # * subscribe
  # * subscribed
  # * unavailable
  # * unsubscribe
  # * unsubscribed
  # See RFC3921 - 2.2.1. for explanation.
  class Presence < XMLStanza
    ##
    # Create presence stanza
    # ito:: [JID] Initial to attribute
    # ishow:: [String] Initial Availability Status
    # istatus:: [String] Initial status message
    # ipriority:: [Fixnum] Initial priority value
    def initialize(ito=nil, ishow=nil, istatus=nil, ipriority=nil)
      super("presence")
      set_to(ito) unless ito.nil?
      set_show(ishow)
      set_status(istatus)
      set_priority(ipriority)
    end

    ##
    # Create a new presence from a stanza
    # result:: [Presence] Imported XMLStanza
    def Presence.import(xmlstanza)
      Presence::new.import(xmlstanza)
    end

    ##
    # Get Availability Status (RFC3921 - 5.2)
    def show
      each_element('show') { |show| return(show.text) }
      nil
    end

    ##
    # Set Availability Status
    #
    # Valid values according to RFC3921:
    # * nil (Online, no <show/> element)
    # * "away"
    # * "chat" (Free for chat)
    # * "dnd" (Do not disturb)
    # * "xa" (Extended away)
    def show=(val)
      xe = nil
      each_element('show') { |show| xe = show }
      if xe.nil?
        xe = add_element('show')
      end
      
      if val.nil?
        delete_element(xe)
      else
        xe.text = val
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
    def priority=(val)
      xe = nil
      each_element('priority') { |prio| xe = prio }
      if xe.nil?
        xe = add_element('priority')
      end
      
      if val.nil?
        delete_element(xe)
      else
        xe.text = val
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
