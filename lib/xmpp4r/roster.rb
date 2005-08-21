#  XMPP4R - XMPP Library for Ruby
#  Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
#  Released under GPL v2 or later

require 'xmpp4r/iq'
require 'xmpp4r/iqqueryroster'
require 'xmpp4r/callbacklist'

module Jabber
  ##
  # A class to track Roster and Presence updates
  class Roster
    ##
    # vCard pool
    # mostly filled by results to request_vcard()
    # ::vcards [Hash] with [JID] keys and [IqVcard] values
    attr_reader :vcards
    
    ##
    # Initialize a new Roster handler
    # stream:: [Stream] Where to register callback handlers
    # initial_presence:: [Presence] Initial presence to be send.
    # priority:: [Integer] Priority for callbacks
    # ref:: [String] Reference for callbacks
    def initialize(stream, initial_presence=nil, priority=0, ref=nil)
      @stream = stream

      @rosterquery = IqQueryRoster.new
      @presences = {}
      @vcards = {}

      @rosteritemcbs = CallbackList::new
      @presencecbs = CallbackList::new
      @vcardcbs = CallbackList::new
      
      stream.add_iq_callback(priority, ref) { |iq|
        iq_callback(iq)
      }
      stream.add_presence_callback(priority, ref) { |pres|
        presence_callback(pres)
      }

      # Request roster
      stream.send(Jabber::Iq.new_rosterget)

      # Send initial presence
      unless initial_presence.nil?
        stream.send(initial_presence)
      end
    end

    ##
    # <iq/> callback handler
    # (registered by constructor and used internally only)
    def iq_callback(iq)
      if (iq.type == 'result') || (iq.type == 'set')
        if iq.query.kind_of?(IqQueryRoster)
          # Add all items seperately so we can call the rosteritem_callback
          iq.query.each { |item|
            olditem = @rosterquery[item.jid]

            @rosterquery.add(item)

            curitem = @rosterquery[item.jid]
            @rosteritemcbs.process(RosterChange::new(olditem, curitem))
          }

          iq.consume
        end
      end

      if iq.vcard.kind_of?(IqVcard)
        @vcards[iq.from] = iq.vcard
        # We must callback with the full Iq, the single vCard doesn't contain the JID
        @vcardcbs.process(iq)
      end
    end

    ##
    # <presence/> callback handler
    # (registered by constructor and used internally only)
    #
    # Presence stanzas with type 'error' or 'probe' will be silently discarded
    def presence_callback(pres)
      if (pres.type != :error) && (pres.type != :probe)
        oldpres = @presences[pres.from]
        @presences[pres.from] = pres
        @presencecbs.process(RosterChange::new(oldpres, pres))
      end
    end

    ##
    # Get a RosterItem or Presence by JID
    # jid:: [JID] to look for
    # result:: [RosterItem] if [jid] has no resource (nil) or [Presence]
    def [](jid)
      if jid.resource.nil?
        @rosterquery[jid]
      else
        @presences[jid]
      end
    end

    ##
    # Get the known resources of a given JID
    # jid:: [JID]
    # result:: [Array] of [JID]
    def resources(jid)
      jids = []
      @presences.each_key { |pjid|
        jids.push(pjid) if jid.strip == pjid.strip
      }
      jids
    end

    ##
    # Send request for a vCard
    # jid:: [JID] of desired vCard
    #   (resource stripping recommended, omit if requesting user's own vCard)
    def request_vcard(jid=nil)
      @stream.send(Iq::new_vcard('get', jid))
    end

    ##
    # Add a callback/block to process updated RosterItem elements
    # proc or block:: Will be called with an [RosterChange] containing old [RosterItem] and new [RosterItem]
    def add_rosteritem_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @rosteritemcbs.add(priority, ref, block)
    end

    ##
    # Delete a RosterItem callback
    # ref:: [String] Reference given when added
    def delete_rosteritem_callback(ref)
      @rosteritemcbs.delete(ref)
    end

    ##
    # Add a callback/block to process updated presence stanzas.
    # This differs from [Stream#add_presence_callback] by submitting the
    # previous presence stanza of the resource too.
    # proc or block:: Will be called with an [RosterChange] containing old [RosterItem] and new [RosterItem]
    def add_presence_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @presencecbs.add(priority, ref, block)
    end

    ##
    # Delete a presence callback
    # ref:: [String] Reference given when added
    def delete_presence_callback(ref)
      @presencecbs.delete(ref)
    end

    ##
    # Add a callback/block to process updated vCards
    # proc or block:: Will be called with an [Iq] containing the newly retrieved [Vcard]
    def add_vcard_callback(priority = 0, ref = nil, proc=nil, &block)
      block = proc if proc
      @vcardcbs.add(priority, ref, block)
    end

    ##
    # Delete a vCard callback
    # ref:: [String] Reference given when added
    def delete_vcard_callback(ref)
      @vcardcbs.delete(ref)
    end
  end

  ##
  # A class passed to callbacks
  #
  # Consumption is a hack here, but works flawless
  class RosterChange
    attr_accessor :old, :cur
    
    def initialize(old, cur)
      @old = old
      @cur = cur
      @consumed = false
    end

    def consume
      @consumed = true
    end

    def consumed?
      @consumed
    end
  end
end
