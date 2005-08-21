#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

require 'xmpp4r/iqquery'

module Jabber
  ##
  # Class for handling roster updates
  #
  # You must do 'client.send(Iq.new_rosterget)' or else you will
  # have nothing to put in receive_iq()
  #
  # You must require 'xmpp4r/rosterquery' to use this class
  # as its functionality is not needed for a working XMPP implementation.
  # This will make [IqQuery] convert all Queries with namespace 'jabber:iq:roster'
  # to [IqQueryRoster]
  class IqQueryRoster < IqQuery
    ##
    # Create a new <query xmlns='jabber:iq:roster'/>
    # stream:: [Stream] Stream to handle
    def initialize
      super
      add_namespace('jabber:iq:roster')
    end

    ##
    # Add an element to the roster
    #
    # Converts <item/> elements to RosterItem
    def add(element)
      if element.kind_of?(REXML::Element) && (element.name == 'item')
        item = RosterItem::new.import(element)
        # XPath injection here?
        delete_element("item[@jid='#{item.jid}']")
        super(item)
      else
        super(element)
      end
    end

    ##
    # Iterate through all items
    def each(&block)
      each_element { |item|
        # XPath won't work here as it's missing a prefix...
        yield(item) if item.kind_of?(RosterItem)
      }
    end

    ##
    # Get roster item by JID
    # jid:: [JID] or [Nil]
    # result:: [RosterItem]
    def [](jid)
      each { |item|
        return(item) if item.jid == jid.strip
      }
      nil
    end

    ##
    # Get all items
    # result:: [Array] of [RosterItem]
    def to_a
      a = []
      each { |item|
        a.push(item)
      }
      a
    end

    ##
    # Update roster by <iq/> stanza
    # (to be fed by an iq_callback)
    # iq:: [Iq] Containing new roster
    # filter:: [Boolean] If false import non-roster-like results too
    def receive_iq(iq, filter=true)
      if filter && (((iq.type != 'set') && (iq.type != 'result')) || (iq.queryns != 'jabber:iq:roster'))
        return
      end

      import(iq.query)
    end

    ##
    # Output for "p"
    def inspect
      jids = to_a.collect { |item| item.jid.inspect }
      jids.join(', ')
    end
  end

  ##
  # Class containing the <item/> elements of the roster
  #
  # The 'name' attribute has been renamed to 'iname' here
  # as 'name' is already used by REXML::Element for the
  # element's name. It's still name='...' in XML.
  class RosterItem < XMLElement
    ##
    # Construct a new roster item
    # jid:: [JID] Jabber ID
    # iname:: [String] Name in the roster
    # subscription:: [String] Type of subscription (see subscription=())
    # ask:: [String] or [Nil] Can be "ask"
    def initialize(jid=nil, iname=nil, subscription=nil, ask=nil)
      super('item')
      self.jid = jid
      self.iname = iname
      self.subscription = subscription
      self.ask = ask
    end

    ##
    # Create new RosterItem from REXML::Element
    def RosterItem.import(item)
      RosterItem::new.import(item)
    end

    ##
    # Get name of roster item
    def iname
      attributes['name']
    end

    ##
    # Set name of roster item
    def iname=(val)
      attributes['name'] = val
    end

    ##
    # Get JID of roster item
    # Resource of the JID will be stripped
    def jid
      JID::new(attributes['jid']).strip
    end

    ##
    # Set JID of roster item
    def jid=(val)
      attributes['jid'] = val.nil? ? nil : val.to_s
    end

    ##
    # Get subscription type of roster item
    # result:: [Symbol] or [Nil] The following values are valid according to RFC3921:
    # * :both
    # * :from
    # * :none
    # * :remove
    # * :to
    def subscription
      case attributes['subscription']
        when 'both' then :both
        when 'from' then :from
        when 'none' then :none
        when 'remove' then :remove
        when 'to' then :to
        else nil
      end
    end

    ##
    # Set subscription type of roster item
    # val:: [Symbol] or [Nil] See subscription for possible Symbols
    def subscription=(val)
      case val
        when :both then attributes['subscription'] = 'both'
        when :from then attributes['subscription'] = 'from'
        when :none then attributes['subscription'] = 'none'
        when :remove then attributes['subscription'] = 'remove'
        when :to then attributes['subscription'] = 'to'
        else attributes['subscription'] = nil
      end
    end

    ##
    # Get if asking for subscription
    # result:: [Symbol] nil or :subscribe
    def ask
      case attributes['ask']
        when 'subscribe' then :subscribe
        else nil
      end
    end

    ##
    # Set if asking for subscription
    # val:: [Symbol] nil or :subscribe
    def ask=(val)
      case val
        when :subscribe then attributes['ask'] = 'subscribe'
        else attributes['ask'] = nil
      end
    end

    ##
    # Get groups the item belongs to
    # result:: [Array] of [String] The groups
    def groups
      result = []
      each_element('group') { |group|
        result.push(group.text)
      }
      result
    end

    ##
    # Set groups the item belongs to,
    # deletes old groups first.
    #
    # See JEP 0083 for nested groups
    # ary:: [Array] New groups, duplicate values will be removed
    def groups=(ary)
      # Delete old group elements
      delete_elements('group')

      # Add new group elements
      ary.uniq.each { |group|
        add_element('group').text = group
      }
    end
  end

  IqQuery.add_namespace('jabber:iq:roster', IqQueryRoster)
end
