# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/rexmladdons'

module Jabber
  ##
  # This class is the root of all XML stanzas which are Jabber messages.
  # Children of those XMLElement should only be REXML::Element, not
  # XMLElement.
  class XMLElement < REXML::Element
    ##
    # Construct an XMLElement for the supplied tag and attributes
    #
    # tag:: [String] XML tag
    # attributes:: [Hash = {}] The attribute hash[attribute]=value
    def initialize(arg, parent=nil, context=nil)
      super(arg, parent, context)
      @consumed = false
    end

    ##
    # Makes some changes to the structure of an XML element to help
    # it respect the specification. For example, in a message, we should
    # have <subject/> < <body/> < { rest of tags }
    def normalize
    end

    ##
    # When an xml is received from the Jabber service and a XMLElement is
    # created, it is propogated to all filters and listeners.  Any one of
    # those can consume the element to prevent its propogation to other
    # filters or listeners. This method marks the element as consumed.
    #
    # return:: [Jabber::Protocol::XMLElement] self for chaining
    def consume
      @consumed = true
      self
    end

    ##
    # Checks if the element is consumed
    #
    # return:: [Boolean] True if the element is consumed
    def consumed?
      @consumed
    end
  end
end
