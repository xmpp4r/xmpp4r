#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

module Jabber
  ##
  # Class for handling roster updates
  #
  # Supports reading only
  #
  # You must do 'client.send(Iq.new_rosterget)' or else you will
  # have nothing to put in receive_iq()
  class Roster < XMLElement
    ##
    # Create a new Roster
    # stream:: [Stream] Stream to handle
    def initialize
      super('query')
      add_namespace('jabber:iq:roster')
    end

    ##
    # Create new Roster from XMLElement
    # (mostly <iq><query>...</query></iq>)
    # item:: [XMLElement] iq.query to import
    def Roster.import(query)
      Roster::new.import(query)
    end

    ##
    # Add an element to the roster
    #
    # Converts <item/> elements to RosterItem
    def add(element)
      if element.name == 'item'
        super(RosterItem::import(element))
      else
        super(element)
      end
      element
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
    # filter:: [Boolean] If false import non-roster results too
    def receive_iq(iq, filter=true)
      if filter && ((iq.type != 'result') || (iq.queryns != 'jabber:iq:roster'))
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
    # Create new RosterItem from XMLElement
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
      attributes['jid'] = val.to_s
    end

    ##
    # Get subscription type of roster item
    def subscription
      attributes['subscription']
    end

    ##
    # Set subscription type of roster item
    #
    # The following values are valid according to RFC3921 - 2.2.1.:
    # * unavailable
    # * subscribe
    # * subscribed
    # * unsubscribe
    # * unsubscribed
    # * probe
    # * error
    def subscription=(val)
      attributes['subscription'] = val
    end

    ##
    # Get if asking for subscription
    # result:: [String] Mostly nil or 'subscribe'
    def ask
      attributes['ask']
    end

    ##
    # Set if asking for subscription
    # val:: [String] Should be nil or 'subscribe'
    def ask=(val)
      attributes['ask'] = val
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
    # ary:: [Array] New groups
    def groups=(ary)
      # Delete old group elements
      delete_element('group')

      # Add new group elements
      ary.each { |group|
        add_element('group').text = group
      }
    end
  end
end
