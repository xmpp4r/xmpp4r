module IRC
  ##
  # This module defines all IRC events which can be overwritten
  # by classes deriving from IRC::Client. All methods have empty bodies.
  #
  # Note that nicks and channels that are passed to the event-handlers
  # MAY carry additional attributes like @%+ prefixes for channel
  # privileges or be in form of a hostmask (nick!user@host.domain).
  module IRCEvents
    ##
    # Received a PRIVMSG
    # from:: [String] Nick!user@host
    # to:: [String] Channel or nick
    # text:: [String] Message
    def on_msg(from, to, text)
    end
    ##
    # Received a NOTICE
    # from:: [String] Nick!user@host
    # to:: [String] Channel or nick
    # text:: [String] Message
    def on_notice(from, to, text)
    end
    ##
    # Received error that there is no MOTD.
    # This means the same as on_endofmotd: you're now able to join channels.
    def on_err_nomotd
    end
    ##
    # Server begins to send the MOTD
    def on_motdstart
    end
    ##
    # Received a line of the MOTD
    def on_motd(from, text)
    end
    ##
    # Server has finished sending MOTD.
    # You're now able to join channels.
    def on_endofmotd
    end
    ##
    # Client#nick failed: the nickname is already in use
    def on_err_nicknameinuse
    end
    ##
    # Client#nick failed: the desired nickname is invalid
    def on_err_erroneousnickname
    end
    ##
    # Getting a part of the user-list for a channel
    # channel:: [String] Channel
    # names:: [Array] of [String] Nicknames with @%+ prefixes
    def on_names(channel, names)
    end
    ##
    # User-list arrived
    def on_endofnames(channel)
    end
    ##
    # Server sends features
    # (usually before MOTD)
    def on_features(features, msg)
    end
    ##
    # Seen a MODE event
    # from:: [String] Invoking nick
    # target:: [String] Channel or Nick
    def on_mode(from, target, flags, params)
    end
    ##
    # Seen a TOPIC event
    def on_topic(from, channel, text)
    end
    ##
    # There is no topic set
    def on_rpl_notopic(channel, text)
    end
    ##
    # The topic is...
    # channel:: [String]
    # text:: [String] Topic
    def on_rpl_topic(channel, text)
    end
    ##
    # Extended topic info
    # channel:: [String]
    # nick:: [String] Nick of who set the topic
    # time:: [Fixnum] Time when topic was set as Unix timestamp
    def on_rpl_topicinfo(channel, nick, time)
    end
    ##
    # Client#join failed, channel is protected with a key (+k)
    def on_err_badchannelkey(channel, text)
    end
    ##
    # Something like Client#topic failed
    # because the channel is +t and you don't have +o.
    def on_chanoprivsneeded(channel, msg)
    end
    ##
    # Somebody left a channel
    def on_part(from, channel, reason)
    end
    ##
    # Somebody joined a channel
    def on_join(from, channel)
    end
    ##
    # Somebody has quit from IRC
    def on_quit(from, reason)
    end
    ##
    # Somebody kicked somebody from a channel
    # from:: [String] Kicker
    # channel:: [String] Channel being kicked from
    # nick:: [String] Victim
    # reason:: [String] Kick reason
    def on_kick(from, channel, nick, reason)
    end
    ##
    # Somebody has been killed
    def on_kill(from, nick, reason)
    end
    ##
    # Received a CTCP request
    def on_ctcp(from, to, text)
    end
    ##
    # Received a CTCP reply
    def on_ctcp_reply(from, to, text)
    end
    ##
    # Somebody changed his nick
    def on_nick(from, to)
    end
    ##
    # User information of Client#whois request
    def on_whoisuser(nick, user, host, realname)
    end
    ##
    # Server information of Client#whois request
    def on_whoisserver(nick, server, serverinfo)
    end
    ##
    # Idle information of Client#whois request
    def on_whoisidle(nick, info)
    end
    ##
    # All information of a Client#whois request has been sent by the server
    def on_endofwhois(nick)
    end
    ##
    # Channels information of Client#whois request
    # channels:: [Array] of [String] Channels prefixed with @%+ for the users privileges
    def on_whoischannels(nick, channels)
    end
  end
end
