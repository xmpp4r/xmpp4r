require 'timeout'
require 'iconv'
require 'irc'

##
# Represents a user known from a channel
class ChannelUser
  # Attributes to keep track of
  attr_accessor :nick, :hostmask, :modes
  def initialize(nick)
    @nick = nick
    @modes = {}
    @modes_sent = {:dirty=>true}  # Dummy value to be different to @modes upon initialization
  end

  # Compares modes with the modes when the last presence was retrieved
  def dirty?
    not (@modes == @modes_sent)
  end

  ##
  # Give the user prefixes like @%+
  def give_flags(flags)
    flags.scan(/./) { |flag|
      case flag
        when '@' then @modes['o'] = true
        when '%' then @modes['h'] = true
        when '+' then @modes['v'] = true
      end
    }
  end

  ##
  # Is this channel-operator (+o)?
  def op?
    @modes.has_key? 'o'
  end

  ##
  # Is this a half-op (+h)?
  def halfop?
    @modes.has_key? 'h'
  end

  ##
  # Has voice (+v)?
  def voice?
    @modes.has_key? 'v'
  end

  ##
  # Compose a XMucUserItem element with nick and the
  # appropriate role and affiliation set
  def item(room_jid=nil)
    i = Jabber::XMucUserItem.new
    i.jid = Jabber::JID.new @nick, room_jid.domain if room_jid
    i.nick = @nick
    if op?
      i.role = :moderator
      i.affiliation = :owner
    elsif halfop?
      i.role = :moderator
      i.affiliation = :admin
    elsif voice?
      i.role = :participant
      i.affiliation = :member
    else
      i.role = :visitor
      i.affiliation = :none
    end
    i
  end

  ##
  # Return a Jabber::Presence stanza
  # with IRC-chanmodes mapped to Jabber::XMucUserItem
  # room_jid:: [Jabber::JID] JID of the component to set from-attribute
  # to:: [Jabber::JID] JID of destination to set to-attribute
  # result:: [Jabber::Presence]
  def presence(room_jid, to=nil)
    pres = Jabber::Presence.new
    pres.from = jid room_jid
    pres.to = to

    pres.add(Jabber::XMucUser.new).add(item(room_jid))

    @modes_sent = @modes.dup

    pres
  end

  ##
  # Same as presence,
  # but to indicate that this user is currently leaving.
  # code:: [Fixnum] Optional MUC status-code
  # reason:: [String] Optional leaving reason
  # result:: [Jabber::Presence]
  def unavailable_presence(room_jid, to=nil, code=nil, reason=nil)
    pres = presence(room_jid, to)
    pres.type = :unavailable

    x = pres.first_element 'x'
    if code
      x.add(REXML::Element.new('status')).attributes['code'] = code.to_s
    end

    i = x.first_element 'item'
    i.affiliation = :none
    i.role = :none
    i.reason = reason

    pres
  end

  ##
  # Return the JID of the user according to the rooms' JID
  # room_jid:: [Jabber::JID]
  # result:: [Jabber::JID]
  def jid(room_jid)
    Jabber::JID.new room_jid.node, room_jid.domain, nick
  end
end

##
# Track a WHOIS request to compose a vCard
class WhoisRequest
  attr_reader :nick, :stanza_id
  # Attributes to be set by event-handlers in IRCClient
  attr_accessor :hostmask, :realname
  attr_accessor :server, :serverinfo
  attr_accessor :idleinfo
  attr_accessor :channels
  ##
  # nick:: [String] Nick of whom WHOIS was requested
  # stanza_id:: [String] Optional id-attribute of the Jabber::Iq stanza which asked for vCard
  def initialize(nick, stanza_id)
    @nick = nick
    @stanza_id = stanza_id
    @hostmask = nil
    @realname = nil
    @server = nil
    @serverinfo = nil
    @idleinfo = {}
    @channels = []
  end

  ##
  # Compose a vCard from WHOIS information
  def vcard
    @idleinfo.each { |k,v|
      if k =~ /time/
        @idleinfo[k] = Time.at(v.to_i).to_s
      end
    }
    
    Jabber::IqVcard.new({'NICKNAME'=>@nick,
                         'FN'=>@realname,
                         'ROLE'=>@idleinfo.collect { |k,v| "#{k}: #{v}" }.join(', '),
                         'EMAIL/USERID'=>@hostmask,
                         'ORG/ORGNAME'=>"#{@server} (#{@serverinfo})",
                         'ORG/ORGUNIT'=>@channels})
  end
end

##
# Tracking a jabber:iq:version request,
class VersionRequest
  attr_reader :nick, :stanza_id
  # Attribute to be fed by IRCClient#on_ctcp_reply
  attr_accessor :version

  ##
  # See WhoisRequest#initialize
  def initialize(nick, stanza_id)
    @nick = nick
    @stanza_id = stanza_id
    @version = ''
  end

  ##
  # Compose an IqQueryVersion <query/> element to be included into
  # answer.
  #
  # Because CTCP returns a String, only IqQueryVersion#iname will be set
  def query
    Jabber::IqQueryVersion.new(@version)
  end
end

##
# The class forming a MUC (JEP-0045) room whilst acting as an IRC client.
#
# There is no extra layer of seperation between these two things to keep
# overhead small and allow interaction as closely as possible.
class IRCClient < IRC::Client
  # Default character encoding for IRC if none was given in config-file. Also fallback.
  IRC_DEFAULT_CHARSET = 'ISO-8859-1'
  # Character encoding for Jabber is always UTF-8.
  XMPP_CHARSET = 'UTF-8'

  def initialize(transport, client_jid, room_jid)
    @transport = transport
    @client_jid = client_jid
    @room_jid = room_jid
    @password = nil
    
    @active = false
    @sent_own_presence = false
    @client_presence = nil
    @prefixes = []
    @chanmodes = []
    @users = {}
    @users_lock = Mutex.new

    @whois_requests = []
    @whois_requests_lock = Mutex.new

    @version_requests = []
    @version_requests_lock = Mutex.new

    @topic_info_nick = nil
    @topic_info_time = nil
    @topic_info_lock = Mutex.new
  end

  ##
  # Is the IRC connection alive?
  def active?
    @active
  end

  ##
  # Start IRC::Client#run in a seperate thread after having connected
  def activate
    @active = true
    Thread.new {
      begin
        run
      rescue IRC::ConnectionClosed => e
        @transport.send user(@room_jid.resource).unavailable_presence(@room_jid, @client_jid, 332, e.to_s)
      end
      @active = false
    }
  end

  ##
  # Send a presence from the room to indicate room unavailability
  def send_error_presence(error, text=nil)
    pres = Jabber::Presence.new
    pres.from = @room_jid.strip
    pres.to = @client_jid
    pres.type = :error
    pres.add Jabber::Error.new(error, text)
    @transport.send pres
  end

  ##
  # Look at the last presence received from the client
  # and update or clear the IRC AWAY-message
  def update_away
    if active?
      if [:away, :dnd, :xa].include? @client_presence.show
        status = @client_presence.status.to_s
        away(status.size > 0 ? status : @client_presence.show.to_s)
      else
        away
      end
    end
  end

  ##
  # Handle a Jabber::Message stanza received by XMPP:
  # * New subjects
  # * Messages to the room
  # * Private messages to room participants
  # * Invitation to other JIDs
  # * Invalid messages if the originating user hasn't joined
  def handle_message(message)
    if active?
      if message.subject and message.type == :groupchat   # Subject
        topic @room_jid.node, xmpp_to_irc(message.subject)
      elsif message.body                                  # Text message
        message.body.split(/\n/).each { |line|
          if message.type == :groupchat
            # To IRC
            if line =~ /^\/me (.+)$/
              ctcp @room_jid.node, "ACTION #{xmpp_to_irc($1)}"
            else
              msg @room_jid.node, xmpp_to_irc(line)
            end
            # Echo to Jabber
            message = Jabber::Message.new(@client_jid, line)
            message.type = :groupchat
            message.from = @room_jid
            @transport.send message
          elsif message.type == :chat
            if line =~ /^\/me (.+)$/
              ctcp message.to.resource, "ACTION #{xmpp_to_irc($1)}"
            else
              msg message.to.resource, xmpp_to_irc(line)
            end
          end
        }
      else                                                # Possible invitation
        x = nil
        message.each_element('x') { |e| x = e if e.kind_of? Jabber::XMucUser }
        if x
          invite = x.first_element 'invite'
          if invite.kind_of? Jabber::XMucUserInvite       # Invitation
            invite.from = message.from
            invitation = Jabber::Message.new(invite.to, "You have been invited to IRC channel #{@room_jid.node} by #{message.from}")
            invitation.from = @room_jid.strip
            invitation.add(Jabber::XMucUser.new).add(invite)
            xconference = invitation.add REXML::Element.new('x')
            xconference.add_namespace 'jabber:x:conference'
            xconference.attributes['jid'] = @room_jid.strip
            xconference.text = invite.reason
            @transport.send invitation
          end
        end
      end
    elsif message.type != :error
      reply = message.answer
      reply.type = :error
      reply.add Jabber::Error.new('not-acceptable', 'You must join this room to send messages')
      @transport.send reply
    end
  end

  ##
  # Handle a Jabber::Presence
  # * Updates IRC AWAY-message
  # * Connect to IRC server (when user attempts to join the room)
  # * QUIT from IRC server (when user leaves the room)
  def handle_presence(pres)
    @client_presence = pres

    unless active?
      if pres.type != :unavailable and pres.type != :error
        pres.each_element('x') { |x|
          if x.kind_of? Jabber::XMuc
            @password = x.password
          end
        }

        realname = nil
        begin
          Timeout::timeout(10) {  # Wait max 10 seconds for vCard
            iq = Jabber::Iq.new(:get, @client_jid.strip)
            iq.from = @room_jid.strip
            # Use JEP-0164 (vCard Filtering) and don't request the avatar...
            filter = iq.add(Jabber::IqVcard.new).add(REXML::Element.new('filter'))
            filter.add_namespace 'vcard-temp-filter'
            filter.add(REXML::Element.new('PHOTO'))

            @transport.send_with_id(iq) { |reply|
              if reply.vcard
                realname = reply.vcard['FN'] || "#{reply.vcard['N/GIVEN']} #{reply.vcard['N/FAMILY']}"
              end
              true
            }
          }
        rescue Jabber::ErrorException
        rescue Timeout::Error
        end
        
        # The field may have been present but empty...
        if realname.to_s.strip.size < 1
          realname = "xmpp:#{@client_jid}"
        else
          realname = "#{realname.to_s.strip} (xmpp:#{@client_jid})"
        end
        
        begin
          connect pres.to.resource, pres.from.node, realname, @transport.irc_conf['server'], @transport.irc_conf['port']
          activate
        rescue SystemCallError => e
          send_error_presence 'service-unavailable', e.to_s
        end
      end
    else
      if pres.type == :unavailable or pres.type == :error
        quit(pres.show)
      else
        update_away

        if pres.to != @room_jid
          self.nick = pres.to.resource
        end
      end
    end
  end

  ##
  # Handle a Jabber::Iq
  # * Translate jabber:iq:version results to CTCP VERSION and jabber:iq:time to CTCP TIME replies
  # * Start WHOIS upon vCard get-request
  # * Send CTCP VERSION upon jabber:iq:version get-request
  # * MODE-changes for MUC Admin use-cases
  # * Service Discovery
  def handle_iq(iq)
    # Translate iq-results to CTCP-replies
    if iq.type == :result and active?
      if iq.queryns == 'jabber:iq:version'
        ctcp_reply iq.to.resource, "VERSION #{iq.query.iname} #{iq.query.version} #{iq.query.os}"
      elsif iq.queryns == 'jabber:iq:time'
        ctcp_reply iq.to.resource, "TIME #{iq.query.text}"
      end
    end

    # Translate vCard-requests to WHOIS and jabber:iq:version to CTCP VERSION
    if iq.type == :get and active?
      if iq.vcard.kind_of? Jabber::IqVcard
        @whois_requests_lock.synchronize {
          @whois_requests.push WhoisRequest.new(iq.to.resource, iq.id)
        }
        whois iq.to.resource
      elsif iq.query.kind_of? Jabber::IqQueryVersion
        @version_requests_lock.synchronize {
          @version_requests.push VersionRequest.new(iq.to.resource, iq.id)
        }
        ctcp iq.to.resource, 'VERSION'
      end
    end

    # MODE changes (moderator/admin use-cases)
    if iq.queryns == 'http://jabber.org/protocol/muc#admin' and active?

      # Retrieval of affiliation/role lists
      if iq.type == :get
        # Compose answer with all users first...
        reply = iq.answer false
        reply.type = :result
        query = reply.add REXML::Element.new('query')
        query.add_namespace iq.queryns
        all_items = []
        @users_lock.synchronize {
          @users.each { |nick,user|
            all_items.push user.item @room_jid
          }
        }
        
        # Filter by what the user requested
        filter = iq.query.first_element 'item'
        if filter
          frole = filter.attributes['role']
          faffiliation = filter.attributes['affiliation']

          all_items.each { |item|
            role = item.attributes['role']
            affiliation = item.attributes['affiliation']
            if frole and role != frole
              # Skip
            elsif faffiliation and affiliation != faffiliation
              # Skip
            else
              query.add item
            end
          }
        end

        @transport.send reply
        
      # MODE changes (moderator/admin use-cases)
      elsif iq.type == :set
        # TODO: Rather implement Jabber::IqQueryMucAdmin...

        # New modes of a user
        modes = {}

        iq.query.each_element('item') { |item|
          nick = (item.attributes['nick'] || Jabber::JID.new(item.attributes['jid']).node).downcase
          next if nick.to_s.size < 1

          # Change of role list
          if item.attributes['role']
            case item.attributes['role']
              when 'moderator' then
                modes[nick] = 'ov'
              when 'participant' then
                modes[nick] = 'v'
              when 'visitor' then
                modes[nick] = ''
              when 'none' then
                kick(@room_jid.node, nick, item.first_element_text('reason'))
            end
          # Change of affiliation list
          # (no support of half-op here, as many IRC networks don't support it)
          elsif item.attributes['affiliation']
            case item.attributes['affiliation']
              when 'owner' then
                modes[nick] = 'ov'
              when 'admin' then
                modes[nick] = 'ov'
              when 'member' then
                modes[nick] = 'v'
              when 'none' then
                modes[nick] = ''
            end
          end
        }

        # Find mode differentials...
        flags_set = ''
        flags_delete = ''
        flags_users_set = []
        flags_users_delete = []
        # Find modes to set
        @users_lock.synchronize {
          @users.each { |nick,user|
            nick = nick.downcase
            # Only for users which the requester wanted to modify
            next unless modes.has_key? nick

            # Find modes to set
            (modes[nick] || '').scan(/./) { |flag|
              unless user.modes[flag] # If user hasn't this flag already
                flags_set += flag
                flags_users_set.push user.nick
              end
            }
            # Find modes to delete
            user.modes.each { |flag,flagv|
              unless (modes[nick] || '').include? flag
                flags_delete += flag
                flags_users_delete.push user.nick
              end
            }
          }
        }

        mode(@room_jid.node, "+#{flags_set}-#{flags_delete}", (flags_users_set + flags_users_delete).join(' '))

        reply = iq.answer(false)
        reply.type = :result
        @transport.send reply
      end
    end

    # Service Discovery
    if iq.type == :get
      if iq.query.kind_of? Jabber::IqQueryDiscoInfo
        reply = iq.answer
        reply.type = :result
        reply.query.add Jabber::DiscoIdentity.new('conference', @room_jid.node, 'irc')
        reply.query.add Jabber::DiscoFeature.new(Jabber::XMuc.new.namespace)
        reply.query.add Jabber::DiscoFeature.new(Jabber::XMucUser.new.namespace)
        reply.query.add Jabber::DiscoFeature.new(Jabber::IqQueryDiscoInfo.new.namespace)
        @transport.send reply
      elsif iq.query.kind_of? Jabber::IqQueryDiscoItems
        reply = iq.answer
        reply.type = :result
        # No browseable items
        @transport.send reply
      end
    end
  end

  ##
  # Get a channel user by nick,
  # removes optional prefixes and sets corresponding channel modes,
  # removes optional hostmask and updates user
  # add_new_user:: [Boolean] Whether to add unknown users to the list (to ignore users which are not in channel)
  def user(nick, add_new_user=true)
    @users_lock.synchronize {
      flags = ''
      while @prefixes.include? nick[0..0]
        flags += nick[0..0]
        nick = nick[1..-1]
      end
      nick, hostmask = nick.split(/!/, 2)

      u = (@users.has_key? nick) ? @users[nick] : ChannelUser.new(nick)
      @users[nick] = u if add_new_user
      u.give_flags flags
      u.hostmask = hostmask if hostmask
      u
    }
  end

  ##
  # Strip IRC color codes and optionally convert charsets
  #
  # Charset conversion as follows:
  # * Try to convert to user set charset
  # * When not succeeded, try to convert to default IRC charset
  # * When not succeeded, escape non-ASCII characters
  # str:: [String] Text with possibly bogus characters
  # result:: [String] UTF-8 encoded text suitable for XMPP
  def irc_to_xmpp(str)
    str.gsub!(/\x02/, '')
    str.gsub!(/\x03\d\d?,\d\d?/, '')
    str.gsub!(/\x03\d\d?/, '')
    str.gsub!(/\x03/, '')
    str.gsub!(/\x16/, '')
    str.gsub!(/\x1f/, '')

    begin
      Iconv.new(XMPP_CHARSET, @transport.irc_conf['charset'] || IRC_DEFAULT_CHARSET).iconv(str)
    rescue Iconv::IllegalSequence
      begin
        Iconv.new(XMPP_CHARSET, IRC_DEFAULT_CHARSET).iconv(str)   # Fall back to default charset
      rescue Iconv::IllegalSequence
        str.inspect.sub(/^"/, '').sub(/"$/, '')                   # String#inpsect escapes all non-ascii characters :-)
      end
    end
  end

  ##
  # Convert XMPP (UTF-8 charset) to IRC
  #
  # There's no fall-back mechanism as Jabber servers usually disconnect
  # clients sending invalid encoded characters
  def xmpp_to_irc(str)
    Iconv.new(@transport.irc_conf['charset'] || IRC_DEFAULT_CHARSET, XMPP_CHARSET).iconv(str)
  end

  ##
  # Iterate through all pending WHOIS requests
  # filtered by nick
  def with_whois_request(nick)
    @whois_requests_lock.synchronize {
      @whois_requests.each { |request|
        yield request if request.nick == nick
      }
    }
  end

  def on_whoisuser(nick, username, host, realname)
    with_whois_request(nick) { |request|
      request.hostmask = irc_to_xmpp "#{username}@#{host}"
      request.realname = irc_to_xmpp realname
    }
  end
  def on_whoisserver(nick, server, serverinfo)
    with_whois_request(nick) { |request|
      request.server = irc_to_xmpp server
      request.serverinfo = irc_to_xmpp serverinfo
    }
  end
  def on_whoisidle(nick, info)
    with_whois_request(nick) { |request|
      info2 = {}
      info.each { |k,v| info2[irc_to_xmpp(k)] = irc_to_xmpp v }
      request.idleinfo = info2
    }
  end
  def on_whoischannels(nick, channels)
    with_whois_request(nick) { |request|
      request.channels = channels.collect { |channel| irc_to_xmpp channel }
    }
  end
  def on_endofwhois(nick)
    @whois_requests_lock.synchronize {
      @whois_requests.delete_if { |request|
        if request.nick == nick
          iq = Jabber::Iq.new(:result)
          iq.from = user(nick, false).jid(@room_jid)
          iq.to = @client_jid
          iq.id = request.stanza_id
          iq.add request.vcard
          @transport.send iq
          true
        else
          false
        end
      }
    }
  end

  ##
  # Somebody is being renamed
  # * Send unavailable_presence for old nick
  # * Update user-list
  # * Send new presence for new nick
  def on_nick(from, to)
    u = user(from)

    pres = u.unavailable_presence(@room_jid, @client_jid, 303)
    pres.first_element('x/item').nick = to
    @transport.send pres

    @users_lock.synchronize {
      @users.delete from

      if @room_jid.resource == u.nick  # That's ourself!
        @room_jid = Jabber::JID.new @room_jid.node, @room_jid.domain, to
      end
      u.nick = to

      @users[u.nick] = u
    }

    @transport.send u.presence(@room_jid, @client_jid)
  end

  def on_err_nicknameinuse
    unless @sent_own_presence
      quit
    end

    send_error_presence 'conflict', 'Your nickname is already in use'
  end

  def on_err_erroneousnickname
    unless @sent_own_presence
      quit
    end

    send_error_presence 'jid-malformed', 'Erroneous nickname'
  end

  ##
  # No MOTD means we can do what we would do on_endofmotd...
  def on_err_nomotd
    on_endofmotd
  end

  ##
  # End of MOTD means we can go on and join a room
  def on_endofmotd
    join @room_jid.node, @password
    update_away
  end

  def on_features(features, msg)
    if features.has_key? 'PREFIX'
      @prefixes = features['PREFIX']
    end
    if features.has_key? 'CHANMODES'  # xchat-2.6.0/src/common/modes.c:414 mode_has_arg()
      # Type A, Type B, Type C, Type D
      @chanmodes = features['CHANMODES'].split(/,/)
      # A: 0 parameters
      # B: 1 parameter
      # C: 1 parameter if '+'
      # D: 0 parameters
    end
  end

  def on_names(channel, names)
    if channel == @room_jid.node
      unless @sent_own_presence
        @transport.send user(@room_jid.resource).presence(@room_jid, @client_jid)
        @sent_own_presence = true
      end

      names.each { |name|
        @transport.send user(name).presence(@room_jid, @client_jid)
      }
    end
  end

  def on_endofnames(channel)
    #topic(channel)
  end

  def on_err_badchannelkey(channel, text)
    if channel == @room_jid.node
      quit

      send_error_presence 'not-authorized', irc_to_xmpp(text)
    end
  end

  def on_join(from, channel)
    if channel == @room_jid.node
      @sent_own_presence = true if from == @room_jid.resource

      @transport.send user(from).presence(@room_jid, @client_jid)
    end
  end

  def on_quit(from, reason)
    f = user(from)
    presence = f.unavailable_presence(@room_jid, @client_jid)
    presence.type = :unavailable
    presence.status = irc_to_xmpp reason if reason
    @transport.send presence

    @users_lock.synchronize {
      @users.delete f.nick
    }
  end

  def on_kick(from, channel, nick, reason)
    if channel == @room_jid.node
      f = user(from)
      t = user(nick)

      @transport.send t.unavailable_presence(@room_jid, @client_jid, 307, "Kicked by #{f.nick}: #{irc_to_xmpp reason.to_s}")

      if t.nick == @room_jid.resource # Is it ourself?
        quit
      else                            # Somebody else has been kicked
        @users_lock.synchronize {
          @users.delete t.nick
        }
      end
    end
  end

  ##
  # Handle a KILL message
  #
  # We only handle ourselves here, because KILLing of others
  # appears as QUIT.
  def on_kill(from, nick, reason)
    f = user(from)
    t = user(nick)
    if t.nick == @room_jid.resource
      @transport.send t.unavailable_presence(@room_jid, @client_jid, 307, "Killed by #{f.nick}: #{irc_to_xmpp reason.to_s}")

      if t.nick == @room_jid.resource # Is it ourself?
        quit
      else                            # Somebody else has been killed
        @users_lock.synchronize {
          @users.delete t.nick
        }
      end
    end
  end

  ##
  # Because we're single-channel, the same procedure as with on_quit
  def on_part(from, channel, reason)
    if channel == @room_jid.node
      on_quit from, reason
    end
  end

  ##
  # Receiving a PRIVMSG from IRC
  # * either to channel (groupchat)
  # * or to other destination (chat)
  def on_msg(from, to, text)
    if to == @room_jid.node
      message = Jabber::Message.new(@client_jid, irc_to_xmpp(text))
      message.type = :groupchat
      message.from = user(from, false).jid(@room_jid)
      @transport.send message
    else
      message = Jabber::Message.new(@client_jid, irc_to_xmpp(text))
      message.type = :chat
      message.from = user(from, false).jid(@room_jid)
      @transport.send message
    end
  end

  ##
  # MODE change on channel
  # * Echo to user
  # * Update users
  # * Send updated presence for users with changed flags
  def on_mode(from, target, flags, params)
    if target == @room_jid.node
      # Announce...

      message = Jabber::Message.new(@client_jid, "#{user(from, false).nick} set mode: #{target} #{flags} #{params.join(' ')}")
      message.type = :groupchat
      message.from = @room_jid.strip
      @transport.send message

      # Handle...

      # Scan flags
      op = nil
      flags.scan(/./) { |ch|
        if ch == '+'
          op = :set
        elsif ch == '-'
          op = :delete
        elsif op == :set and (@prefixes.include? ch or @chanmodes[1].include? ch or @chanmodes[2].include? 'ch')
          arg = params.shift
          if @prefixes.include? ch
            u = user(arg, false)
            u.modes[ch] = true
          end
        elsif op == :delete and (@prefixes.include? ch or @chanmodes[1].include? ch)
          arg = params.shift
          if @prefixes.include? ch
            u = user(arg, false)
            u.modes.delete ch
          end
        end
      }
      # Send updated presences
      @users_lock.synchronize {
        @users.each { |nick,u|
          if u.dirty?
            @transport.send u.presence(@room_jid, @client_jid)
          end
        }
      }
    end
  end

  ##
  # Topic change
  def on_topic(from, channel, text)
    if channel == @room_jid.node
      message = Jabber::Message.new(@client_jid, irc_to_xmpp("* #{user(from, false).nick} has changed the topic to: #{text}"))
      message.type = :groupchat
      message.from = user(from, false).jid(@room_jid)
      message.subject = irc_to_xmpp text
      @transport.send message
    end
  end
  def on_rpl_notopic(channel, text)
    if channel == @room_jid.node
      message = Jabber::Message.new(@client_jid, irc_to_xmpp(text))
      message.type = :groupchat
      message.from = @room_jid.strip
      message.subject = ''
      @transport.send message
    end
  end
  def on_rpl_topic(channel, text)
    if channel == @room_jid.node
      Thread.new {
        # Wait 5 seconds for topicinfo to arrive
        @topic_info_lock.lock
        begin
          Timeout::timeout(5) {
            @topic_info_lock.lock
            @topic_info_lock.unlock
          }
        rescue Timeout::Error
        end

        message = Jabber::Message.new(@client_jid, irc_to_xmpp("* #{@topic_info_nick ? user(@topic_info_nick, false).nick : 'Somebody'} has set the topic to: #{text}"))
        message.type = :groupchat
        message.from = (@topic_info_nick ? user(@topic_info_nick, false).jid(@room_jid) : @room_jid.strip)
        message.subject = irc_to_xmpp text
        message.add(Jabber::XDelay.new).stamp = @topic_info_time if @topic_info_time
        @transport.send message

        @topic_info_nick = nil
        @topic_info_time = nil
        @topic_info_lock.unlock
      }
    end
  end
  def on_rpl_topicinfo(channel, nick, time)
    if channel == @room_jid.node
      @topic_info_nick = nick
      @topic_info_time = Time.at(time)
      @topic_info_lock.unlock
    end
  end

  def on_chanoprivsneeded(channel, msg)
    if channel == @room_jid.node
      message = Jabber::Message.new(@client_jid, msg)
      message.type = :groupchat
      message.from = @room_jid.strip
      @transport.send message
    end
  end

  ##
  # Received a CTCP request
  #
  # Translates ACTION into /me
  #
  # Translates VERSION and TIME to jabber:iq:version and jabber:iq:time,
  # sends Jabber::Iq. There is no need to track the stanza, because
  # it is originated from the specific sender nick. handle_iq will simply
  # translate the answer to a CTCP-reply.
  def on_ctcp(from, to, text)
    request, text = text.split(/ /, 2)
    query_method = case request
      when 'VERSION' then 'jabber:iq:version'
      when 'TIME' then 'jabber:iq:time'
      when 'ACTION' then on_msg(from, to, "/me #{text}")
      else nil
    end

    if query_method
      iq = Jabber::Iq.new_query :get, @client_jid
      iq.from = user(from, false).jid(@room_jid)
      iq.type = :get
      iq.query.add_namespace query_method
      @transport.send iq
    end
  end

  ##
  # Received a CTCP-reply
  #
  # VERSION responses will be translated into
  # jabber:iq:version by pending version_requests
  # to keep track of stanza-id.
  def on_ctcp_reply(from, to, text)
    type, text = text.split(/ /, 2)
    if type == 'VERSION'
      @version_requests_lock.synchronize {
        @version_requests.delete_if { |request|
          if request.nick == user(from, false).nick
            request.version = text
            iq = Jabber::Iq.new(:result)
            iq.from = user(from, false).jid(@room_jid)
            iq.to = @client_jid
            iq.id = request.stanza_id
            iq.add request.query
            @transport.send iq
            true
          else
            false
          end
        }
      }
    end
  end
end
