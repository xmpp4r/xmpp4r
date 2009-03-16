require 'xmpp4r/stream'

module Jabber
  module Reliable
    
    class Connection < Jabber::Client
      def initialize(full_jid, config)
        super(full_jid)
        @servers = config[:servers]
        @port = config[:port] || 5222
        @max_retry = config[:max_retry] || 30
        @retry_sleep = config[:retry_sleep] || 2
        if(@servers.nil? or @servers.empty?)
          @servers = [@jid.domain]
        end
      end
      
      def connect
        retry_count = 0
        server_to_use = nil
        server_pool = @servers.dup.sort{ rand <=> rand }
        begin
          server_to_use = server_pool.shift
          server_pool.push(server_to_use)

          Jabber::debuglog "timeout will be: #{@retry_sleep.to_f}"
          Timeout.timeout(@retry_sleep.to_f){
            Jabber::debuglog "trying to connect to #{server_to_use}"
            super(server_to_use, @port)
          }

          Jabber::debuglog self.jid.to_s + " connected to " + server_to_use.to_s
          Jabber::debuglog "out of possible servers " + @servers.inspect
        rescue Exception, Timeout::Error => e
          Jabber::warnlog "#{server_to_use} error: #{e.inspect}. Will attempt to reconnect in #{@retry_sleep}"
          sleep(@retry_sleep.to_f)
          if(retry_count >= @max_retry.to_i)
            Jabber::warnlog "reached max retry count on exception, failing"
            raise e
          end
          retry_count += 1
          retry
        end
      end
      
    end
    
    class Listener
      def initialize(full_jid, password, config)
        @config = config
        @password = password
        @connection = Connection.new(full_jid, config)
        @connection.add_message_callback do |msg|
          self.on_message(msg)
        end
        
        #We could just reconnect in @connection.on_exception, 
        #but by raising into this seperate thread, we avoid growing our stack trace
        @reconnection_thread = Thread.new do
          first_run = true
          begin
            self.start unless first_run
            loop{ Thread.pass }
          rescue => e
            first_run = false
            retry
          end
        end
        @connection.on_exception do |e, connection, where_failed|
          unless @connection.is_connected?
            @reconnection_thread.raise(e)
          end
        end
      end
      
      def start
        connect
        auth
        send_presence
      end
      
      def connect
        @connection.connect        
      end
      
      def auth
        @connection.auth(@password)
      end
      
      def send_presence
        presence_message = @config[:presence_message]
        if presence_message && !presence_message.empty?
          @connection.send(Jabber::Presence.new.set_show(:chat).set_status(presence_message))
        end
      end
      
      #TODO: test and fix situation where we get disconnected while sending but then successfully reconnect 
      # (and make sure in such cases we resent)
      def send_message(message)
        @connection.send(message)
      end
    end
    
  end
end
