class ListenerMocker
  
  def self.with_socket_mocked(callback_proc)
    TCPSocket.class_eval{ @@with_socket_mocked_callback_proc = callback_proc }
    TCPSocket.class_eval do
      alias_method :initialize_old, :initialize
      def initialize(*args)
        initialize_old(*args) if @@with_socket_mocked_callback_proc.call(args)        
      end
    end    
    yield
  ensure
    TCPSocket.class_eval do
      alias_method :initialize, :initialize_old
    end    
  end
  
  
  def self.mock_out(listener)
    listener.instance_eval do
      @connection.instance_eval do
        class << self
          attr_accessor :messagecbs, :connected
          @@mock_clients = {}
          @@tracker_of_callers = {}
          
          def connect
            Jabber::debuglog("(in mock) connected #{@jid.bare}")
            self.connected = true          
          end
          
          def close!
            @@mock_clients[@jid.bare.to_s] = nil
            @@tracker_of_callers[@jid.bare.to_s] = nil
            self.connected = false
          end
          
          def auth(password)
            auth_nonsasl(password)
          end
          
          def auth_nonsasl(password, digest=true)
            Jabber::debuglog("(in mock) authed #{@jid.bare}") 
          
            if(@@mock_clients[@jid.bare.to_s])
              #raise a stack trace about multiple clients
              raise "\n\n ---> READ ME: this is actualy 2 stack traces: <---- \n\n"+
              "There is already a client connected on that jid #{@jid.bare.to_s}. "+
              "The mock library cannot support multiple listeners connected as the same user! originally called in:\n"+
              @@tracker_of_callers[@jid.bare.to_s].backtrace.join("\n")+"\n\n second trace: \n"
            else
              #store a stack trace so that next time we have multiple client, we can alert about it...
              begin
                throw "just saving a stack trace"
              rescue => e
                @@tracker_of_callers[@jid.bare.to_s] = e
              end
            end

            @@mock_clients[@jid.bare.to_s] = self
            true
          end
          
          def send(xml, &block)
            Jabber::debuglog("(in mock) sending #{xml} #{xml.class}")
            if(xml.is_a?(Jabber::Message))
              xml.from = @jid
              # unless xml.to
              #   raise "no jid!"
              # end
              if @@mock_clients[xml.to.bare.to_s]
                Jabber::debuglog("(in mock) to #{xml.to.bare.to_s}")
                @@mock_clients[xml.to.bare.to_s].messagecbs.process(xml)
              else
                Jabber::debuglog("(in mock) no client listening as #{xml.to.bare.to_s}")
              end
            end
          end          
          
          def is_connected?
            self.connected
          end          
        end
      end
    end
    
    listener
  end
  
end