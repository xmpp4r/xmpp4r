# =XMPP4R - XMPP Library for Ruby
# License:: GPL (v2 or later)
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iqquery'

module Jabber
  ##
  # Class for handling Service Discovery queries,
  # items
  # (JEP 0030)
  class IqQueryDiscoItems < IqQuery
    ##
    # Create a new query
    def initialize
      super
      add_namespace('http://jabber.org/protocol/disco#items')
    end

    ##
    # Add a children element
    #
    # Converts <identity/> elements to [DiscoIdentity]
    # and <feature/> elements to [DiscoFeature]
    def add(xmlelement)
      if xmlelement.kind_of?(REXML::Element)

        if xmlelement.name == 'item'
          super(DiscoItem::new.import(xmlelement))
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

  IqQuery.add_namespace('http://jabber.org/protocol/disco#items', IqQueryDiscoItems)

  ##
  # Service Discovery item to add() to IqQueryDiscoItems
  #
  # Please note that JEP 0030 requires the jid to occur
  class DiscoItem < REXML::Element
    def initialize(jid=nil, iname=nil, node=nil)
      super('item')
      set_jid(jid)
      set_iname(iname)
      set_node(node)
    end

    ##
    # Get the item's jid or nil
    # result:: [String]
    def jid
      JID::new(attributes['jid'])
    end

    ##
    # Set the item's jid
    # val:: [String]
    def jid=(val)
      attributes['jid'] = val.to_s
    end

    ##
    # Set the item's jid (chaining-friendly)
    def set_jid(val)
      self.jid = val
      self
    end

    ##
    # Get the item's name or nil
    #
    # This has been renamed from <name/> to "iname" here
    # to keep REXML::Element#name accessible
    # result:: [String]
    def iname
      attributes['name']
    end

    ##
    # Set the item's name
    # val:: [String]
    def iname=(val)
      attributes['name'] = val
    end

    ##
    # Set the item's name (chaining-friendly)
    def set_iname(val)
      self.iname = val
      self
    end

    ##
    # Get the item's node or nil
    # result:: [String]
    def node
      attributes['node']
    end

    ##
    # Set the item's node
    # val:: [String]
    def node=(val)
      attributes['node'] = val
    end

    ##
    # Set the item's node (chaining-friendly)
    def set_node(val)
      self.node = val
      self
    end
  end
end

