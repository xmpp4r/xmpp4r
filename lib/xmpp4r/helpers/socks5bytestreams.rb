require 'socket'
require 'digest/sha1'
require 'callbacks'
require 'xmpp4r/iq/query/bytestreams'
require 'xmpp4r/helpers/socks5bytestreamsserver'

module Jabber
  module Helpers
    ##
    # Can be thrown upon communication error with
    # a streamhost by SOCKS5BytestreamsInitiator#open
    # and SOCKS5BytestreamsTarget#accept
    class SOCKSError < RuntimeError; end

    ##
    # SOCKS5 Bytestreams (JEP-0065) implementation
    #
    # Don't use directly, use SOCKS5BytestreamsInitiator
    # and SOCKS5BytestreamsTarget
    class SOCKS5Bytestreams
      attr_reader :streamhost_used
      def initialize(stream, session_id, initiator_jid, target_jid)
        @stream = stream
        @session_id = session_id
        @initiator_jid = (initiator_jid.kind_of?(String) ? JID.new(initiator_jid) : initiator_jid)
        @target_jid = (target_jid.kind_of?(String) ? JID.new(target_jid) : target_jid)
        @socks = nil
        @streamhost_used = nil
        @streamhost_cbs = CallbackList.new
      end

      ##
      # Add a callback that will be called when there is action regarding
      # SOCKS stream-hosts
      #
      # Usage of this callback is optional and serves informational purposes only.
      #
      # proc/block takes three arguments:
      # * The StreamHost instance that is currently being tried
      # * State information (is either :connecting, :authenticating, :success or :failure)
      # * The exception value for the state :failure, else nil
      def add_streamhost_callback(priority = 0, ref = nil, proc=nil, &block)
        block = proc if proc
        @streamhost_cbs.add(priority, ref, block)
      end

      ##
      # Receive from the stream-host
      # length:: [Fixnum] Amount of bytes
      # result:: [String] (or [nil] if finished)
      def receive(length=512)
        @socks.read(length)
      end

      ##
      # Send to the stream-host
      # buf:: [String] Data
      # result:: [Fixnum] Amount of bytes sent
      def send(buf)
        @socks.write(buf)
        # FIXME: On FreeBSD this throws Errno::EPERM after it has already written a few
        # kilobytes, and when there are multiple sockets. ktrace told, that this originates
        # from the syscall, not ruby.
      end

      ##
      # Close the stream-host connection
      def close
        @socks.close
      end

      ##
      # Query a JID for its stream-host information
      #
      # SOCKS5BytestreamsInitiator#add_streamhost can do this for you.
      # Use this method if you plan to do multiple transfers, so
      # you can cache the result.
      # stream:: [Stream] to operate on
      # streamhost:: [JID] of the proxy
      # my_jid:: [JID] Optional sender JID for Component operation
      def self.query_streamhost(stream, streamhost, my_jid=nil)
        res = nil

        iq = Iq::new(:get, streamhost)
        iq.from = my_jid
        iq.add(IqQueryBytestreams.new)
        stream.send_with_id(iq) { |reply|
          if reply.type == :result
            reply.query.each_element { |e|
              if e.kind_of?(StreamHost)
                e.jid = reply.from  # Help misconfigured proxys
                res = e
              end
            }
          end
          true
        }

        if res and res.jid and res.host and res.port
          res
        else
          nil
        end
      end

      private

      ##
      # The address the stream-host expects from us.
      # According to JEP-0096 this is the SHA1 hash
      # of the concatenation of session_id,
      # initiator_jid and target_jid.
      # result:: [String] SHA1 hash
      def stream_address
        Digest::SHA1.new("#{@session_id}#{@initiator_jid}#{@target_jid}").hexdigest
      end

      ##
      # Try a streamhost
      # result:: [TCPSocket]
      def connect_socks(streamhost)
        host = streamhost.host
        port = streamhost.port

        Jabber::debuglog("SOCKS5 Bytestreams: connecting to proxy #{host}:#{port}")
        @streamhost_cbs.process(streamhost, :connecting, nil)
        socks = TCPSocket.new(host, port)

        Jabber::debuglog("SOCKS5 Bytestreams: connected, authenticating")
        @streamhost_cbs.process(streamhost, :authenticating, nil)
        socks.write("\x05\x01\x00")
        recv = socks.read(2)
        if recv.nil? or recv != "\x05\x00"
          socks.close
          raise SOCKSError.new("Invalid SOCKS5 authentication: #{recv.inspect}")
        end
        socks.write("\x05\x01\x00\x03#{stream_address.size.chr}#{stream_address}\x00\x00")
        recv = socks.read(7 + stream_address.size)
        if recv.nil? or recv[0..1] != "\005\000"
          socks.close
          raise SOCKSError.new("Invalid SOCKS5 connect: #{recv.inspect}")
        end
        Jabber::debuglog("SOCKS5 Bytestreams: authenticated")
        @streamhost_cbs.process(streamhost, :success, nil)
        socks
      end
    end

    
    ##
    # SOCKS5Bytestreams implementation for the initiator side
    class SOCKS5BytestreamsInitiator < SOCKS5Bytestreams
      attr_reader :streamhosts

      def initialize(stream, session_id, initiator_jid, target_jid)
        super
        @streamhosts = []
      end

      ##
      # Add a streamhost which will be offered to the target
      #
      # streamhost:: can be:
      # * [StreamHost] if already got all information (host/port)
      # * [SOCKS5BytestreamsServer] if this is the local streamhost
      # * [String] or [JID] if information should be automatically resolved by SOCKS5Bytestreams::query_streamhost
      def add_streamhost(streamhost)
        if streamhost.kind_of?(StreamHost)
          @streamhosts << streamhost
        elsif streamhost.kind_of?(SOCKS5BytestreamsServer)
          streamhost.each_streamhost(@initiator_jid) { |sh|
            @streamhosts << sh
          }
        elsif streamhost.kind_of?(String) or streamhost.kind_of?(JID)
          @streamhosts << SOCKS5Bytestreams::query_streamhost(@stream, streamhost, @initiator_jid)
        else
          raise "Unknwon streamhost type: #{streamhost.class}"
        end
      end

      ##
      # Send the configured streamhosts to the target,
      # wait for an answer and
      # connect to the host the target chose.
      def open
        iq1 = Iq::new(:set, @target_jid)
        iq1.from = @initiator_jid
        bs = iq1.add IqQueryBytestreams.new(@session_id)
        @streamhosts.each { |se|
          bs.add(se)
        }

        peer_used = nil
        @stream.send_with_id(iq1) { |response|
          if response.type == :result and response.query.kind_of?(IqQueryBytestreams)
            peer_used = response.query.streamhost_used
            raise "No streamhost-used" unless peer_used
            raise "Invalid streamhost-used" unless peer_used.jid
          end
          true
        }

        @streamhost_used = nil
        @streamhosts.each { |sh|
          if peer_used.jid == sh.jid
            @streamhost_used = sh
            break
          end
        }
        if @streamhost_used.jid == @initiator_jid
          # This is our own JID, so the target chose SOCKS5BytestreamsServer
          @socks = @streamhost_used.server.peer_sock(stream_address)
          raise "Target didn't connect" unless @socks
        else
          begin
            @socks = connect_socks(@streamhost_used)
          rescue Exception => e
            Jabber::debuglog("SOCKS5 Bytestreams: #{e.class}: #{e}\n#{e.backtrace.join("\n")}")
            @streamhost_cbs.process(@streamhost_used, :failure, e)
            raise e
          end
          iq2 = Iq::new(:set, @streamhost_used.jid)
          iq2.add(IqQueryBytestreams.new(@session_id)).activate = @target_jid.to_s
          @stream.send_with_id(iq2) { |reply|
            reply.type == :result
          }
        end
      end
    end

    ##
    # SOCKS5 Bytestreams implementation of the target site
    class SOCKS5BytestreamsTarget < SOCKS5Bytestreams
      def initialize(stream, session_id, initiator_jid, target_jid)
        super

        @connect_lock = Mutex.new
        @error = nil

        @stream.add_iq_callback(200, callback_ref) { |iq|
          if iq.type == :set and iq.from == @initiator_jid and iq.to == target_jid and iq.query.kind_of?(IqQueryBytestreams)
            begin
              @stream.delete_iq_callback(callback_ref)

              iq.query.each_element('streamhost') { |streamhost|
                if streamhost.host and streamhost.port and not @socks
                  begin
                    @socks = connect_socks(streamhost)
                    @streamhost_used = streamhost
                  rescue Exception => e
                    Jabber::debuglog("SOCKS5 Bytestreams: #{e.class}: #{e}\n#{e.backtrace.join("\n")}")
                    @streamhost_cbs.process(streamhost, :failure, e)
                  end
                end
              }

              reply = iq.answer(false)
              if @streamhost_used
                reply.type = :result
                reply.add(IqQueryBytestreams.new)
                reply.query.add(StreamHostUsed.new(@streamhost_used.jid))
              else
                reply.type = :error
                reply.add(Error.new('item-not-found'))
              end
              @stream.send(reply)
            rescue Exception => e
              @error = e
            end
              
            @connect_lock.unlock
            true
          else
            false
          end
        }

        @connect_lock.lock
      end

      ##
      # Wait until the stream has been established
      #
      # May raise various exceptions
      def accept
        @connect_lock.lock
        @connect_lock.unlock
        raise @error if @error
        (@socks != nil)
      end

      private

      def callback_ref
        "Jabber::Helpers::SOCKS5BytestreamsTarget #{@session_id} #{@initiator_jid} #{@target_jid}"
      end
    end
  end
end
