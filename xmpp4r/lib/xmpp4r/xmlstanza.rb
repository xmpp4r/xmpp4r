# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/xmlelement'

module Jabber
  ##
  # root class of all Jabber XML elements
  class XMLStanza < XMLElement

    ##
    # get the to attribute
    #
    # return:: [String] the element's to attribute
    def to
      (a = attribute('to')).nil? ? a : JID::new(a.value)
    end

    ##
    # set the to attribute
    #
    # v:: [String] the value to set
    def to= (v)
      add_attribute('to', v.to_s)
    end

    ##
    # set the to attribute (chaining-friendly)
    #
    # v:: [String] the value to set
    def set_to(v)
      add_attribute('to', v.to_s)
      self
    end

    ##
    # get the from attribute
    #
    # return:: [String] the element's from attribute
    def from
      (a = attribute('from')).nil? ? a : JID::new(a.value)
    end

    ##
    # set the from attribute
    #
    # v:: [String] the value from set
    def from= (v)
      add_attribute('from', v.to_s)
    end

    ##
    # set the from attribute (chaining-friendly)
    #
    # v:: [String] the value from set
    def set_from(v)
      add_attribute('from', v.to_s)
      self
    end

    ##
    # get the id attribute
    #
    # return:: [String] the element's id attribute
    def id
      (a = attribute('id')).nil? ? a : a.value
    end

    ##
    # set the id attribute
    #
    # v:: [String] the value id set
    def id= (v)
      add_attribute('id', v)
    end

    ##
    # set the id attribute (chaining-friendly)
    #
    # v:: [String] the value id set
    def set_id(v)
      add_attribute('id', v)
      self
    end

    ##
    # get the type attribute
    #
    # return:: [String] the element's type attribute
    def type
      (a = attribute('type')).nil? ? a : a.value
    end

    ##
    # set the type attribute
    #
    # v:: [String] the value type set
    def type= (v)
      add_attribute('type', v)
    end

    ##
    # set the type attribute (chaining-friendly)
    #
    # v:: [String] the value type set
    def set_type(v)
      add_attribute('type', v)
      self
    end
  end
end
