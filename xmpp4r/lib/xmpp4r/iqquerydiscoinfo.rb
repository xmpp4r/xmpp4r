# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iqquery'

module Jabber
  ##
  # Class for handling Service Discovery queries,
  # info
  # (JEP 0030)
  class IqQueryDiscoInfo < IqQuery
    ##
    # Create a new query
    def initialize
      super
      add_namespace('http://jabber.org/protocol/disco#info')
    end

    ##
    # Add a children element
    #
    # Converts <identity/> elements to [DiscoIdentity]
    # and <feature/> elements to [DiscoFeature]
    def add(xmlelement)
      if xmlelement.kind_of?(REXML::Element)

        if xmlelement.name == 'identity'
          super(DiscoIdentity::new.import(xmlelement))
        elsif xmlelement.name == 'feature'
          super(DiscoFeature::new.import(xmlelement))
        else
          super(xmlelement)
        end

      else
        super(xmlelement)
      end
    end

    ##
    # Get the queried node or nil
    def node
      attributes['node']
    end

    ##
    # Get the queried node or nil
    def node=(val)
      attributes['node'] = val
    end

    ##
    # Get the queried node or nil
    # (chaining-friendly)
    def set_node(val)
      self.node = val
      self
    end
  end

  IqQuery.add_namespace('http://jabber.org/protocol/disco#info', IqQueryDiscoInfo)

  ##
  # Service Discovery identity to add() to IqQueryDiscoInfo
  #
  # Please note that JEP 0030 requires both category and type to occur
  class DiscoIdentity < REXML::Element
    def initialize(category=nil, iname=nil, type=nil)
      super('identity')
      set_category(category)
      set_iname(iname)
      set_type(type)
    end

    ##
    # Get the identity's category or nil
    # result:: [String]
    def category
      attributes['category']
    end

    ##
    # Set the identity's category
    # val:: [String]
    def category=(val)
      attributes['category'] = val
    end

    ##
    # Set the identity's category (chaining-friendly)
    def set_category(val)
      self.category = val
      self
    end

    ##
    # Get the identity's name or nil
    #
    # This has been renamed from <name/> to "iname" here
    # to keep REXML::Element#name accessible
    # result:: [String]
    def iname
      attributes['name']
    end

    ##
    # Set the identity's name
    # val:: [String]
    def iname=(val)
      attributes['name'] = val
    end

    ##
    # Set the identity's name (chaining-friendly)
    def set_iname(val)
      self.iname = val
      self
    end

    ##
    # Get the identity's type or nil
    # result:: [String]
    def type
      attributes['type']
    end

    ##
    # Set the identity's type
    # val:: [String]
    def type=(val)
      attributes['type'] = val
    end

    ##
    # Set the identity's type (chaining-friendly)
    def set_type(val)
      self.type = val
      self
    end
  end

  ##
  # Service Discovery feature to add() to IqQueryDiscoInfo
  #
  # Please note that JEP 0030 requires var to be set
  class DiscoFeature < REXML::Element
    def initialize(var=nil)
      super('feature')
      set_var(var)
    end

    ##
    # Get the feature's var or nil
    # result:: [String]
    def var
      attributes['var']
    end

    ##
    # Set the feature's var
    # val:: [String]
    def var=(val)
      attributes['var'] = val
    end

    ##
    # Set the feature's var (chaining-friendly)
    def set_var(val)
      self.var = val
      self
    end
  end
end

