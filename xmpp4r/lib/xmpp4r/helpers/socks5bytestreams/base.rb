require 'socket'
require 'thread'
require 'digest/sha1'
require 'callbacks'
require 'xmpp4r/iq/query/bytestreams'

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
  end
end
