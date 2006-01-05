# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'xmpp4r/iq'
require 'xmpp4r/iq/query/roster'
require 'callbacks'

module Jabber
  module Helpers
    ##
    # The Roster helper intercepts <tt><iq/></tt> stanzas with Jabber::IqQueryRoster
    # and <tt><presence/></tt> stanzas, but provides cbs which allow the programmer
    # to keep track of updates.
    class Roster
      ##
      # All items in your roster
      # items:: [Hash] ([JID] => [Helpers::RosterItem])
      attr_reader :items

      ##
      # Initialize a new Roster helper
      #
      # Registers its cbs (prio = 120, ref = "Helpers::Roster")
      #
      # Request a roster
      # (Remember to send initial presence afterwards!)
      def initialize(stream)
        @stream = stream
        @items = {}
        @query_cbs = CallbackList.new
        @update_cbs = CallbackList.new
        @presence_cbs = CallbackList.new
        @subscription_cbs = CallbackList.new

        # Register cbs
        stream.add_iq_callback(120, "Helpers::Roster") { |iq|
          handle_iq(iq)
        }
        stream.add_presence_callback(120, "Helpers::Roster") { |pres|
          handle_presence(pres)
        }
        
        # Request the roster
        rosterget = Iq.new_rosterget
        stream.send(rosterget)
      end

      ##
      # Add a callback to be called when a query has been processed
      #
      # Because update callbacks are called for each roster item,
      # this may be appropriate to notify that *anything* has updated.
      #
      # Arguments for callback block: The received <tt><iq/></tt> stanza
      def add_query_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @query_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for Jabber::Helpers::RosterItem updates
      #
      # Note that this will be called much after initialization
      # for the answer of the initial roster request
      #
      # The block receives two objects:
      # * the old Jabber::Helpers::RosterItem
      # * the new Jabber::Helpers::RosterItem
      def add_update_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @update_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for Jabber::Presence updates
      #
      # This will be called for <tt><presence/></tt> stanzas for known RosterItems.
      # Unknown JIDs may still pass and can be caught via Jabber::Stream#add_presence_callback.
      #
      # The block receives three objects:
      # * the Jabber::Helpers::RosterItem
      # * the old Jabber::Presence (or nil)
      # * the new Jabber::Presence (or nil)
      def add_presence_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @presence_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for subscription updates,
      # which will be called upon receiving a <tt><presence/></tt> stanza
      # with type:
      # * :subscribe (you may want to answer with :subscribed or :unsubscribed)
      # * :subscribed
      # * :unsubscribe
      # * :unsubscribed
      #
      # If type is :subscribe and your callback returns +true+
      # the subscription request will be accepted. Otherwise it
      # will be declined.
      #
      # The block receives two objects:
      # * the Jabber::Helpers::RosterItem (or nil)
      # * the <tt><presence/></tt> stanza
      #
      # Example usage:
      #  my_roster.add_subscription_callback do |item,presence|
      #    if presence.type == :subscribe and accept_subscription_requests
      #      true
      #    else
      #      false
      #    end
      #  end
      def add_subscription_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @subscription_cbs.add(prio, ref, block)
      end

      ##
      # Handle received <tt><iq/></tt> stanzas,
      # used internally
      def handle_iq(iq)
        if iq.query.kind_of?(IqQueryRoster)
          # If the <iq/> contains <error/> we just ignore that
          # and assume an empty roster
          iq.query.each_element('item') do |item|
            # Handle deletion of item
            if item.subscription == :remove
              @items.delete(item.jid)
              return(true)
            end
            
            olditem = nil
            if @items.has_key?(item.jid)
              olditem = RosterItem.new(@stream).import(@items[item.jid])
              @items[item.jid].import(item)
            else
              @items[item.jid] = RosterItem.new(@stream).import(item)
            end
            @update_cbs.process(olditem, @items[item.jid])
          end

          @query_cbs.process(iq)
        else
          false
        end
      end

      ##
      # Handle received <tt><presence/></tt> stanzas,
      # used internally
      def handle_presence(pres)
        item = self[pres.from]
        if [:subscribed, :unsubscribe, :unsubscribed].include?(pres.type)
          @subscription_cbs.process(item, pres)
          true
        elsif pres.type == :subscribe
          if @subscription_cbs.process(item, pres)
            @stream.send(Presence.new.set_to(pres.from.strip).set_type(:subscribed))
          else
            @stream.send(Presence.new.set_to(pres.from.strip).set_type(:unsubscribed))
          end
          true
        else
          unless item.nil?
            update_presence(item, pres)
            true  # Callback consumed stanza
          else
            false # Callback did not consume stanza
          end
        end
      end

      ##
      # Update the presence of an item,
      # used internally
      #
      # Callbacks are called here
      def update_presence(item, pres)
        oldpres = item.presence(pres.from).nil? ? nil : Presence.new.import(item.presence(pres.from))
        item.add_presence(pres)
        @presence_cbs.process(item, oldpres, pres)
      end

      ##
      # Get an item by jid
      #
      # If not available tries to look for it with the resource stripped
      def [](jid)
        if @items.has_key?(jid)
          @items[jid]
        elsif @items.has_key?(jid.strip)
          @items[jid.strip]
        else
          nil
        end
      end

      ##
      # Returns the list of RosterItems which, stripped, are equal to the
      # one you are looking for. 
      def find(jid)
        j = jid.strip
        l = {}
        @items.each_pair do |k, v|
          l[k] = v if k.strip == j
        end
        l
      end

      ##
      # Groups in this Roster,
      # sorted by name
      #
      # Contains +nil+ if there are ungrouped items
      # result:: [Array] containing group names (String)
      def groups
        res = []
        @items.each_pair do |jid,item|
          res += item.groups
          res += [nil] if item.groups == []
        end
        res.uniq.sort { |a,b| a.to_s <=> b.to_s }
      end

      ##
      # Get items in a group
      #
      # When group is nil, return ungrouped items
      # group:: [String] Group name
      def find_by_group(group)
        res = []
        @items.each_pair do |jid,item|
          res.push(item) if item.groups.include?(group)
          res.push(item) if item.groups == [] and group.nil?
        end
        res
      end

      ##
      # Add a user to your roster
      #
      # Threading is encouraged as the function waits for
      # a result. ErrorException is thrown upon error.
      #
      # See Jabber::Helpers::RosterItem#subscribe for details
      # about subscribing. (This method isn't used here but the
      # same functionality applies.)
      #
      # If the item is already in the local roster
      # it will simply send itself
      # jid:: [JID] to add
      # iname:: [String] Optional item name
      # subscribe:: [Boolean] Whether to subscribe to this jid
      def add(jid, iname=nil, subscribe=false)
        if self[jid]
          self[jid].send
        else
          request = Iq.new_rosterset
          request.query.add(Jabber::RosterItem.new(jid, iname))
          @stream.send_with_id(request) { true }
          # Adding to list is handled by handle_iq
        end

        if subscribe
          # Actually the item *should* already be known now,
          # but we do it manually to exclude conditions.
          pres = Presence.new.set_type(:subscribe).set_to(jid)
          @stream.send(pres)
        end
      end
    end

    ##
    # These are extensions to RosterItem to carry presence information.
    # This information is *not* stored in XML!
    class RosterItem < Jabber::RosterItem
      ##
      # Tracked (online) presences of this RosterItem
      attr_reader :presences

      ##
      # Initialize an empty RosterItem
      def initialize(stream)
        super()
        @stream = stream
        @presences = []
      end

      ##
      # Import another element,
      # also import presences if xe is a RosterItem
      # return:: [RosterItem] self
      def import(xe)
        super
        if xe.kind_of?(RosterItem)
          xe.each_presence { |pres|
            add_presence(Presence.new.import(pres))
          }
        end
        self
      end

      ##
      # Send the updated RosterItem to the server,
      # i.e. if you modified iname, groups, ...
      def send
        request = Iq.new_rosterset
        request.query.add(self)
        @stream.send(request)
      end
      
      ##
      # Remove item
      #
      # This cancels both subscription *from* the contact to you
      # and from you *to* the contact.
      #
      # The methods waits for a roster push from the server (success)
      # or throws ErrorException upon failure.
      def remove
        request = Iq.new_rosterset
        request.query.add(Jabber::RosterItem.new(jid, nil, :remove))
        @stream.send_with_id(request) { true }
        # Removing from list is handled by Roster#handle_iq
      end

      ##
      # Is any presence of this person on-line?
      #
      # (Or is there any presence? Unavailable presences are
      # deleted.)
      def online?
        @presences.size > 0
      end
      
      ##
      # Iterate through all received <tt><presence/></tt> stanzas
      def each_presence(&block)
        @presences.each { |pres|
          yield(pres)
        }
      end
      
      ##
      # Get specific presence
      # jid:: [JID] Full JID
      def presence(jid)
        @presences.each do |pres|
          if pres.from == jid
            return(pres)
          end
        end
        nil
      end

      ##
      # Add presence
      # (unless type is :unavailable)
      #
      # This overwrites previous stanzas with the same destination
      # JID to keep track of resources. Presence stanzas with
      # <tt>type == :unavailable</tt> will be deleted as this indicates
      # that this resource has gone offline.
      def add_presence(newpres)
        # Delete old presences with the same JID
        @presences.delete_if do |pres|
          pres.from == newpres.from
        end
        # Add new presence
        unless newpres.type == :unavailable
          @presences.push(newpres)
        end
      end

      ##
      # Send subscription request to the user
      #
      # The block given to Jabber::Helpers::Roster#add_update_callback will
      # be called, carrying the RosterItem with ask="subscribe"
      #
      # This function returns immediately after sending the subscription
      # request and will not wait of approval or declination as it may
      # take months for the contact to decide. ;-)
      def subscribe
        pres = Presence.new.set_type(:subscribe).set_to(jid)
        @stream.send(pres)
      end

      ##
      # Unsubscribe from a contact's presence
      #
      # This method waits for a presence with type='unsubscribed'
      # from the contact. It may throw ErrorException upon failure.
      #
      # subscription attribute of the item is *from* or *none*
      # afterwards. As long as you don't remove that item and
      # subscription='from' the contact is subscribed to your
      # presence.
      def unsubscribe
        pres = Presence.new.set_type(:unsubscribe).set_to(jid)
        @stream.send_with_id(pres) { |answer|
          answer.type == :unsubscribed
        }
      end

      ##
      # Deny the contact to see your presence.
      #
      # This method will not wait and returns immediately
      # as you will need no confirmation for this action.
      #
      # Though, you will get a roster update for that item,
      # carrying either subscription='to' or 'none'.
      def cancel_subscription
        pres = Presence.new.set_type(:unsubscribed).set_to(jid)
        @stream.send_with_id(pres)
      end
    end
  end
end

