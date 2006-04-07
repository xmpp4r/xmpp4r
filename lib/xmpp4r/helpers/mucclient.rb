# =XMPP4R - XMPP Library for Ruby
# License:: Ruby's license (see the LICENSE file) or GNU GPL, at your option.
# Website::http://home.gna.org/xmpp4r/

require 'callbacks'
require 'xmpp4r/presence'
require 'xmpp4r/x/muc'
require 'thread'

module Jabber
  module Helpers
    ##
    # The MUCClient Helper handles low-level stuff of the
    # Multi-User Chat (JEP 0045).
    #
    # Use one instance per room.
    #
    # Note that one client cannot join a single room multiple
    # times. At least the clients' resources must be different.
    # This is a protocol design issue. But don't consider it as
    # a bug, it is just a clone-preventing feature.
    class MUCClient
      ##
      # Sender JID, set this to use MUCClient from Components
      # my_jid:: [JID] Defaults to nil
      attr_accessor :my_jid

      ##
      # MUC room roster
      # roster:: [Hash] of [String] Nick => [Presence]
      attr_reader :roster

      ##
      # MUC JID
      # jid:: [JID] room@component/nick
      attr_reader :jid

      ##
      # Initialize a MUCClient
      #
      # Call MUCClient#join *after* you have registered your
      # callbacks to avoid reception of stanzas after joining
      # and before registration of callbacks.
      # stream:: [Stream] to operate on
      def initialize(stream)
        # Attributes initialization
        @stream = stream
        @my_jid = nil
        @jid = nil
        @roster = {}
        @roster_lock = Mutex.new

        @active = false

        @join_cbs = CallbackList.new
        @leave_cbs = CallbackList.new
        @presence_cbs = CallbackList.new
        @message_cbs = CallbackList.new
        @private_message_cbs = CallbackList.new
      end

      ##
      # Join a room
      #
      # This registers its own callbacks on the stream
      # provided to initialize and sends initial presence
      # to the room. May throw ErrorException if joining
      # fails.
      # jid:: [JID] room@component/nick
      # password:: [String] Optional password
      # return:: [MUCClient] self (chain-able)
      def join(jid, password=nil)
        if active?
          raise "MUCClient already active"
        end
        
        @jid = (jid.kind_of?(JID) ? jid : JID.new(jid))
        activate

        # Joining
        pres = Presence.new
        pres.to = @jid
        pres.from = @my_jid
        xmuc = XMuc.new
        xmuc.password = password
        pres.add(xmuc)

        # We don't use Stream#send_with_id here as it's unknown
        # if the MUC component *always* uses our stanza id.
        error = nil
        @stream.send(pres) { |r|
          if from_room?(r.from) and r.kind_of?(Presence) and r.type == :error
            # Error from room
            error = r.error
            true
          # type='unavailable' may occur when the MUC kills our previous instance,
          # but all join-failures should be type='error'
          elsif r.from == jid and r.kind_of?(Presence) and r.type != :unavailable
            # Our own presence reflected back - success
            handle_presence(r)
            true
          else
            # Everything else
            false
          end
        }

        if error
          deactivate
          raise ErrorException.new(error)
        end

        self
      end

      ##
      # Exit the room
      #
      # * Sends presence with type='unavailable' with an optional
      #   reason in <tt><status/></tt>,
      # * then waits for a reply from the MUC component (will be
      #   processed by leave-callbacks),
      # * then deletes callbacks from the stream.
      # reason:: [String] Optional custom exit message
      def exit(reason=nil)
        unless active?
          raise "MUCClient hasn't yet joined"
        end

        pres = Presence.new
        pres.type = :unavailable
        pres.to = jid
        pres.status = reason if reason
        @stream.send(pres) { |r|
          if r.kind_of?(Presence) and r.type == :unavailable and r.from == jid
            @leave_cbs.process(r)
            true
          else
            false
          end
        }

        deactivate

        self
      end

      ##
      # Is the MUC client active?
      #
      # This is false after initialization,
      # true after joining and
      # false after exit/kick
      def active?
        @active
      end

      ##
      # Send a stanza to the room
      # stanza:: [XMLStanza] to send
      # to:: [String] Stanza destination recipient, or room if +nil+
      def send(stanza, to=nil)
        stanza.from = @my_jid
        stanza.to = JID::new(jid.node, jid.domain, to)
        @stream.send(stanza)
      end

      ##
      # Send a message stanza to the room
      #
      # <tt>stanza.type</tt> will be automatically set to :groupchat if directed
      # to room or :chat if directed to participant.
      # stanza:: [XMLStanza] to send
      # to:: [String] Stanza destination recipient, or room if +nil+
      def send_message(stanza, to=nil)
        stanza.type = to ? :chat : :groupchat
        send(stanza, to)
      end

      ##
      # Add a callback for <presence/> stanzas indicating availability
      # of a MUC participant
      #
      # The callback will be called from MUCClient#handle_presence with
      # one argument: the <presence/> stanza.
      # Note that this stanza will have been already inserted into
      # MUCClient#roster.
      def add_join_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @join_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for <presence/> stanzas indicating unavailability
      # of a MUC participant
      #
      # The callback will be called with one argument: the <presence/> stanza.
      #
      # Note that this is called just *before* the stanza is removed from
      # MUCClient#roster, so it is still possible to see the last presence
      # in the given block.
      #
      # If the presence's origin is your MUC JID, the MUCClient will be
      # deactivated *afterwards*.
      def add_leave_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @leave_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for a <presence/> stanza which is neither a join
      # nor a leave. This will be called when a room participant simply
      # changes his status.
      def add_presence_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @presence_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for <message/> stanza directed to the whole room.
      #
      # See MUCClient#add_private_message_callback for private messages
      # between MUC participants.
      def add_message_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @message_cbs.add(prio, ref, block)
      end

      ##
      # Add a callback for <message/> stanza with type='chat'.
      #
      # These stanza are normally not broadcasted to all room occupants
      # but are some sort of private messaging.
      def add_private_message_callback(prio = 0, ref = nil, proc = nil, &block)
        block = proc if proc
        @message_cbs.add(prio, ref, block)
      end

      ##
      # Does this JID belong to that room?
      # jid:: [JID]
      # result:: [true] or [false]
      def from_room?(jid)
        @jid.strip == jid.strip
      end

      private

      def handle_presence(pres) # :nodoc:
        if pres.type == :unavailable or pres.type == :error
          @leave_cbs.process(pres)
          @roster_lock.synchronize {
            @roster.delete(pres.from.resource)
          }

          if pres.from == jid
            deactivate
          end
        else
          is_join = ! @roster.has_key?(pres.from.resource)
          @roster_lock.synchronize {
            @roster[pres.from.resource] = pres
          }
          if is_join
            @join_cbs.process(pres)
          else
            @presence_cbs.process(pres)
          end
        end
      end

      def handle_message(msg) # :nodoc:
        if msg.type == :chat
          @private_message_cbs.process(msg)
        else  # type == :groupchat or anything else
          @message_cbs.process(msg)
        end
      end

      def activate  # :nodoc:
        @active = true

        # Callbacks
        @stream.add_presence_callback(150, self) { |presence|
          if from_room?(presence.from)
            handle_presence(presence)
            true
          else
            false
          end
        }

        @stream.add_message_callback(150, self) { |message|
          if from_room?(message.from)
            handle_message(message)
            true
          else
            false
          end
        }
      end

      def deactivate  # :nodoc:
        @active = false

        # Callbacks
        @stream.delete_presence_callback(self)
        @stream.delete_message_callback(self)
      end
    end
  end
end
