#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2004 Lucas Nussbaum <lucas@lucas-nussbaum.net>
#  Released under GPL v2 or later

require 'xmpp4r/xmlstanza'

module Jabber
  ##
  # The presence class is used to construct presence messages to 
  # send to the Jabber service.
  #
  class Presence < XMLStanza
    def initialize
      super("presence")
    end

    ##
    # Create a new presence from a stanza
    def Presence.import(xmlstanza)
      Presence::new.import(xmlstanza)
    end
  end
end
