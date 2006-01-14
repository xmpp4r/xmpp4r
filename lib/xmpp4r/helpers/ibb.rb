require 'base64'

# TODO:
# * error handling

module Jabber
  module Helpers
    ##
    # In-Band Bytestreams (JEP-0047) implementation
    #
    # Don't use directly, use IBBInitiator and IBBTarget
    #
    # In-Band Bytestreams should only be used when transferring
    # very small amounts of binary data, because it is slow and
    # increases server load drastically.
    #
    # Note that the constructor takes a lot of arguments. In-Band
    # Bytestreams do not specify a way to initiate the stream,
    # this should be done via Stream Initiation.
    class IBB
      NS_IBB = 'http://jabber.org/protocol/ibb'

      ##
      # Create a new bytestream
      #
      # Will register a <message/> callback to intercept data
      # of this stream. This data will be buffered, you can retrieve
      # it with receive
      def initialize(stream, session_id, my_jid, peer_jid)
        @stream = stream
        @session_id = session_id
        @my_jid = (my_jid.kind_of?(String) ? JID.new(my_jid) : my_jid)
        @peer_jid = (peer_jid.kind_of?(String) ? JID.new(peer_jid) : peer_jid)

        @seq_send = 0
        @seq_recv = 0
        @queue = []
        @queue_lock = Mutex.new
        @pending = Mutex.new
        @pending.lock

        @block_size = 4096  # Recommended by JEP0047

        @stream.add_message_callback(200, "#{callback_ref} close") { |msg|
          data = msg.first_element('data')
          if msg.from == @peer_jid and msg.to == @my_jid and data and data.attributes['sid'] == @session_id
            @queue_lock.synchronize {
              @queue << msg
              @pending.unlock
            }
            true
          else
            false
          end
        }

        @stream.add_iq_callback(200, callback_ref) { |iq|
          close = iq.first_element('close')
          if close and close.attributes['sid'] == @session_id
            @queue_lock.synchronize {
              @queue << iq
              @pending.unlock
            }
            true
          else
            false
          end
        }
      end

      ##
      # Send data
      # buf:: [String]
      def send(buf)
        msg = Message.new
        msg.from = @my_jid
        msg.to = @peer_jid
        
        data = msg.add REXML::Element.new('data')
        data.add_namespace NS_IBB
        data.attributes['sid'] = @session_id
        data.attributes['seq'] = @seq_send
        data.text = Base64::encode64 buf

        # TODO: Implement AMP correctly
        amp = msg.add REXML::Element.new('amp')
        amp.add_namespace 'http://jabber.org/protocol/amp'
        deliver_at = amp.add REXML::Element.new('rule')
        deliver_at.attributes['condition'] = 'deliver-at'
        deliver_at.attributes['value'] = 'stored'
        deliver_at.attributes['action'] = 'error'
        match_resource = amp.add REXML::Element.new('rule')
        match_resource.attributes['condition'] = 'match-resource'
        match_resource.attributes['value'] = 'exact'
        match_resource.attributes['action'] = 'error'
 
        @stream.send(msg)

        @seq_send += 1
        @seq_send = 0 if @seq_send > 65535
      end

      ##
      # Receive data
      #
      # Will wait until the Message with the next sequence number
      # is in the stanza queue.
      def receive
        res = nil

        while res.nil?
          @queue_lock.synchronize {
            @queue.each { |stanza|
              data = stanza.first_element('data')
              if data and data.attributes['seq'] == @seq_recv.to_s
                res = stanza
              end
            }
            
            unless res  # No data in queue, look for close
              @queue.each { |stanza|
                if stanza.kind_of?(Iq) and stanza.first_element('close')
                  answer = stanza.answer(false)
                  answer.type = :result
                  @stream.send(answer)

                  res = stanza
                end
              }
            end
            @queue.delete_if { |stanza| stanza == res }
          }

          @pending.lock unless res
        end

        if res.kind_of?(Message)
          @seq_recv += 1
          @seq_recv = 0 if @seq_recv > 65535
          Base64::decode64(res.first_element('data').text.to_s)
        else
          nil # Closed
        end
      end

      ##
      # Close the stream
      #
      # Waits for acknowledge from peer,
      # may throw ErrorException
      def close
        @stream.delete_message_callback(callback_ref)

        iq = Iq.new(:set, @peer_jid)
        close = iq.add REXML::Element.new('close')
        close.add_namespace IBB::NS_IBB
        close.attributes['sid'] = @session_id

        @stream.send_with_id(iq) { |answer|
          answer.type == :result
        }
      end

      private

      def callback_ref
        "Jabber::Helpers::IBB #{@session_id} #{@initiator_jid} #{@target_jid}"
      end
    end

    ##
    # Implementation of IBB at the initiator side
    class IBBInitiator < IBB
      ##
      # Open the stream to the peer,
      # waits for successful result
      #
      # May throw ErrorException
      def open
        iq = Iq.new(:set, @peer_jid)
        open = iq.add REXML::Element.new('open')
        open.add_namespace IBB::NS_IBB
        open.attributes['sid'] = @session_id
        open.attributes['block-size'] = @block_size

        @stream.send_with_id(iq) { |answer|
          answer.type == :result
        }
      end
    end

    ##
    # Implementation of IBB at the target side
    class IBBTarget < IBB
      def initialize(stream, session_id, initiator_jid, target_jid)
        # Target and Initiator are swapped here, because we're the target
        super(stream, session_id, target_jid, initiator_jid)

        @connect_lock = Mutex.new

        @stream.add_iq_callback(200, "#{callback_ref} open") { |iq|
          open = iq.first_element('open')
          if iq.type == :set and iq.from == @peer_jid and iq.to == @my_jid and open and open.attributes['sid'] == @session_id
            @stream.delete_iq_callback("#{callback_ref} open")

            reply = iq.answer(false)
            reply.type = :result
            @stream.send(reply)
              
            @connect_lock.unlock
            true
          else
            false
          end
        }

        @connect_lock.lock
      end

      ##
      # Wait for the initiator side to start
      # the stream.
      def accept
        @connect_lock.lock
        @connect_lock.unlock
        true
      end
    end
  end
end
