module IRC
  module IRCEvents
    def on_msg(from, to, text)
    end
    def on_notice(from, to, text)
    end
    def on_err_nomotd
    end
    def on_motdstart
    end
    def on_motd(from, text)
    end
    def on_endofmotd
    end
    def on_err_nomotd
    end
    def on_err_nicknameinuse
    end
    def on_err_erroneousnickname
    end
    def on_names(channel, names)
    end
    def on_endofnames(channel)
    end
    def on_features(features, msg)
    end
    def on_mode(from, target, flags, params)
    end
    def on_topic(from, channel, text)
    end
    def on_rpl_notopic(channel, text)
    end
    def on_rpl_topic(channel, text)
    end
    def on_rpl_topicinfo(channel, nick, time)
    end
    def on_err_badchannelkey(channel, text)
    end
    def on_chanoprivsneeded(channel, msg)
    end
    def on_part(from, channel, reason)
    end
    def on_join(from, channel)
    end
    def on_quit(from, reason)
    end
    def on_kick(from, channel, nick, reason)
    end
    def on_kill(from, nick, reason)
    end
    def on_ctcp(from, to, text)
    end
    def on_ctcp_reply(from, to, text)
    end
    def on_nick(from, to)
    end
    def on_whoisuser(nick, user, host, realname)
    end
    def on_whoisserver(nick, server, serverinfo)
    end
    def on_whoisidle(nick, info)
    end
    def on_endofwhois(nick)
    end
    def on_whoischannels(nick, channels)
    end
  end
end
