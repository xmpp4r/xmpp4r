# TODO:
# * Room configuration
# * Handle tons of different JOIN failures

require 'xmpp4r'
require 'xmpp4r/iq/query/version'
require 'xmpp4r/iq/query/discoinfo'
require 'xmpp4r/iq/query/discoitems'
require 'xmpp4r/x/muc'
require 'xmpp4r/x/mucuseritem'
require 'xmpp4r/x/delay'
require 'yaml'

require 'ircclient'

Jabber::debug = true

class IRCTransport < Jabber::Component
  ##
  # Load configuration file from a YAML document named [configfile]
  #
  # Connect the Jabber component and add callbacks
  def initialize(configfile)
    @config = YAML::load File.new(configfile)
    super jabber_conf['jid'], jabber_conf['server'], jabber_conf['port']
    connect
    auth jabber_conf['password']

    # Leave XMPP4R its own thread
    add_stanza_callback { |stanza| Thread.new { handle_stanza stanza } }

    @clients = {}
    @clients_lock = Mutex.new
  end

  ##
  # Return the Jabber-specific part of the configuration
  def jabber_conf
    @config['jabber']
  end

  ##
  # Return the IRC-specific part of the configuration
  def irc_conf
    @config['irc']
  end

  ##
  # We received a stanza
  #
  # Handle it if it's destined for the component or
  # dispatch it to a room, which can be created on demand.
  def handle_stanza(stanza)
    unless stanza.to.node # Directed to component
      if stanza.kind_of? Jabber::Iq and stanza.type == :get
        if stanza.query.kind_of? Jabber::IqQueryDiscoInfo
          reply = stanza.answer
          reply.type = :result
          reply.query.add Jabber::DiscoIdentity.new('conference', jabber_conf['identity'], 'irc')
          reply.query.add Jabber::DiscoFeature.new(Jabber::XMuc.new.namespace)
          reply.query.add Jabber::DiscoFeature.new(Jabber::XMucUser.new.namespace)
          reply.query.add Jabber::DiscoFeature.new(Jabber::IqQueryDiscoInfo.new.namespace)
          reply.query.add Jabber::DiscoFeature.new(Jabber::IqQueryDiscoItems.new.namespace)
          send reply
        elsif stanza.query.kind_of? Jabber::IqQueryDiscoItems
          reply = stanza.answer
          reply.type = :result
          irc_conf['channels'].each { |channel|
            reply.query.add Jabber::DiscoItem.new(Jabber::JID.new(channel, jid.to_s), channel)
          }
          send reply
        end
      end
    else                  # Directed to room
      client = nil
      @clients_lock.synchronize {
        if @clients.has_key? [stanza.from, stanza.to.strip]
          client = @clients[[stanza.from, stanza.to.strip]]
        else
          client = IRCClient.new(self, stanza.from, stanza.to)
          @clients[[stanza.from, stanza.to.strip]] = client
        end
      }

      if stanza.kind_of? Jabber::Message
        client.handle_message stanza
      elsif stanza.kind_of? Jabber::Presence
        client.handle_presence stanza
      elsif stanza.kind_of? Jabber::Iq
        client.handle_iq stanza
      else
      end

      @clients_lock.synchronize {
        @clients.delete_if { |jid,client| not client.active? }
      }
    end
  end

  ##
  # Shutdown the component
  #
  # Instructs all clients to quit and
  # waits until no active clients left
  def shutdown!
    puts "Beginning shutdown"

    @clients_lock.synchronize {
      @clients.each { |jid,client|
        puts "Quitting #{jid[0]} -> #{jid[1]}"
        client.quit "#{self.jid} shutting down"
      }
    }

    begin
      active_clients = 0
      @clients_lock.synchronize {
        @clients.each { |jid,client|
          active_clients += 1 if client.active?
        }
      }
      puts "#{active_clients} active clients remaining"
      
      sleep 1 if active_clients > 0
    end while active_clients > 0

    close
  end
end


##
# main function ;-)

if ARGV.size != 1
  puts "Usage: #{$0} <config.yaml>"
  exit
end

begin
  t = IRCTransport.new ARGV[0]
  Thread.stop
rescue Interrupt => e
  t.shutdown!
end

