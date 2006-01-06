require 'xmpp4r/helpers/mucclient'
require 'xmpp4r/x/delay'

module Jabber
  module Helpers
    ##
    # This class attempts to implement a lot of complexity of the
    # Multi-User Chat protocol. If you want to implement JEP0045
    # yourself, use Jabber::Helpers::MUCClient for some minor
    # abstraction.
    #
    # Minor flexibility penalty: the on_* callbacks are no
    # CallbackLists and may therefore only used once. A second
    # invocation will overwrite the previous set up block.
    #
    # Example usage:
    #   my_muc = Jabber::Helpers::SimpleMUCClient.new(my_client, Jabber::JID.new('jdev@conference.jabber.org/XMPP4R-Bot'))
    #   my_muc.on_message { |time,nick,text|
    #     puts (time || Time.new).strftime('%I:%M') + " <#{nick}> #{text}"
    #   }
    #
    # Please take a look at Jabber::Helpers::MUCClient for
    # SimpleMUCClient#exit (derived from MUCClient#exit) and
    # advanced features.
    class SimpleMUCClient < MUCClient
      ##
      # Initialize a SimpleMUCClient
      # 
      # Calls it superclass MUCClient, thus will join immediately
      # after adding callbacks.
      # stream:: [Stream] to operate on
      # jid:: [JID] room@component/nick
      # password:: [String] Optional password
      def initialize(stream, jid, password=nil)
        super

        @room_message_block = nil
        @message_block = nil
        @private_message_block = nil
        @subject_block = nil

        @subject = nil

        @join_block = nil
        add_join_callback(999) { |pres|
          # Presence time
          time = nil
          pres.each_element('x') { |x|
            if x.kind_of?(XDelay)
              time = x.stamp
            end
          }

          # Invoke...
          @join_block.call(time, pres.from.resource) if @join_block
          false
        }

        @leave_block = nil
        add_leave_callback(999) { |pres|
          # Presence time
          time = nil
          pres.each_element('x') { |x|
            if x.kind_of?(XDelay)
              time = x.stamp
            end
          }

          # Invoke...
          @leave_block.call(time, pres.from.resource) if @leave_block
          false
        }
      end

      private

      def handle_message(msg)
        super

        # Message time (e.g. history)
        time = nil
        msg.each_element('x') { |x|
          if x.kind_of?(XDelay)
            time = x.stamp
          end
        }
        # Sender nick
        nick = msg.from.resource


        if msg.subject
          @subject = msg.subject
          @subject_block.call(time, nick, @subject) if @subject_block
        end
        
        if msg.body
          if nick.nil?
            @room_message_block.call(time, msg.body) if @room_message_block
          else
            if msg.type == :chat
              @private_message_block.call(time, msg.from.resource, msg.body) if @message_block
            elsif msg.type == :groupchat
              @message_block.call(time, msg.from.resource, msg.body) if @message_block
            else
              # ...?
            end
          end
        end
      end

      public

      ##
      # Room subject
      def subject
        @subject
      end

      ##
      # Change the room's subject
      #
      # This will not be reflected by SimpleMUCClient#subject
      # immediately, wait for SimpleMUCClient#on_subject
      def subject=(s)
        msg = Message.new
        msg.subject = s
        send_message(msg)
      end

      ##
      # Send a simple text message
      # text:: [String] Message body
      # to:: [String] Optional nick if directed to specific user
      def say(text, to=nil)
        send_message(Message.new(nil, text), to)
      end

      ##
      # Request the MUC to invite users to this room
      #
      # Sample usage:
      #   my_muc.invite( {'wiccarocks@shakespeare.lit/laptop' => 'This coven needs both wiccarocks and hag66.',
      #                   'hag66@shakespeare.lit' => 'This coven needs both hag66 and wiccarocks.'} )
      # recipients:: [Hash] of [JID] => [String] Reason
      def invite(recipients)
        msg = Message.new
        x = msg.add(XMucUser.new)
        recipients.each { |jid,reason|
          x.add(XMucUserInvite.new(jid, reason))
        }
        send(msg)
      end

      ##
      # Block to be invoked when a message *from* the room arrives
      #
      # Example:
      #   Astro has joined this session
      # block:: Takes two arguments: time, text
      def on_room_message(&block)
        @room_message_block = block
      end

      ##
      # Block to be invoked when a message from a participant to
      # the whole room arrives
      # block:: Takes three arguments: time, sender nickname, text
      def on_message(&block)
        @message_block = block
      end

      ##
      # Block to be invoked when a private message from a participant
      # to you arrives.
      # block:: Takes three arguments: time, sender nickname, text
      def on_private_message(&block)
        @private_message_block = block
      end

      ##
      # Block to be invoked when somebody sets a new room subject
      # block:: Takes three arguments: time, nickname, new subject
      def on_subject(&block)
        @subject_block = block
      end

      ##
      # Block to be called when somebody enters the room
      #
      # If there is a non-nil time passed to the block, chances
      # are great that this is initial presence from a participant
      # after you have joined the room.
      # block:: Takes two arguments: time, nickname
      def on_join(&block)
        @join_block = block
      end

      ##
      # Block to be called when somebody leaves the room
      # block:: Takes two arguments: time, nickname
      def on_leave(&block)
        @leave_block = block
      end
    end
  end
end
