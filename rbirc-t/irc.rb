require 'socket'
require 'ircevents'

module IRC
  class ConnectionClosed < RuntimeError; end
  
  class Connection
    def initialize
      @socket = nil
    end

    def connect(host, port=6667)
      @socket = TCPSocket.new(host, port)
    end

    def recv_line
      begin
        line = @socket.gets
      rescue
        line = nil
      end
      unless line
        begin
          @socket.close
        rescue IOError
        end
        raise ConnectionClosed
      end

      puts "RECEIVED: #{line.inspect}"
      line.gsub!(/[\r\n]+$/, '')
      line
    end

    def send_line(line)
      puts "SENDING: #{line.inspect}"
      @socket.write("#{line}\r\n")
    end
  end

  class Client < Connection
    attr_reader :servername, :serverversion, :usermodes, :channelmodes
    
    include IRCEvents
    
    def connect(nick, user, realname, host, port=6667)
      super(host, port)
      self.nick = nick
      send_line("USER #{user} no no :#{realname}")
    end

    def nick
      @nick
    end

    def nick=(newnick)
      send_line("NICK #{newnick}")
      @nick = newnick
    end

    def join(channel, password=nil)
      if password
        send_line("JOIN #{channel} #{password}")
      else
        send_line("JOIN #{channel}")
      end
    end

    def part(channel, reason)
      if reason
        send_line("PART #{channel} :#{reason}")
      else
        send_line("PART #{channel}")
      end
    end

    def quit(reason=nil)
      if reason
        send_line("QUIT :#{reason}")
      else
        send_line("QUIT")
      end
    end

    def kick(channel, nick, reason=nil)
      if reason
        send_line("KICK #{channel} #{nick} :#{reason}")
      else
        send_line("KICK #{channel} #{nick}")
      end
    end

    def ctcp(receivers, text)
      msg(receivers, "\x01#{text}\x01")
    end

    def ctcp_reply(receivers, text)
      notice(receivers, "\x01#{text}\x01")
    end

    def msg(receivers, text)
      if receivers.kind_of?(Array)
        receivers = receivers.join(',')
      end
      send_line("PRIVMSG #{receivers} :#{text}")
    end

    def notice(receivers, text)
      if receivers.kind_of?(Array)
        receivers = receivers.join(',')
      end
      send_line("NOTICE #{receivers} :#{text}")
    end

    def topic(channel, text=nil)
      if text
        send_line("TOPIC #{channel} :#{text}")
      else
        send_line("TOPIC #{channel}")
      end
    end

    def mode(*args)
      send_line("MODE #{args.join(' ')}")
    end

    def whois(user)
      send_line("WHOIS #{user}")
    end

    def oper(user, password)
      send_line("OPER #{user} #{password}")
    end

    def away(reason=nil)
      if reason
        send_line("AWAY :#{reason}")
      else
        send_line("AWAY")
      end
    end

    def handle_line(line)
      line.chomp!
      from = nil
      
      if line =~ /^:/
        from, line = line.split(/ /, 2)
        from.sub!(/^:/, '')
      end
      command, line = line.split(/ /, 2)
      case command
        when 'PRIVMSG' then
          to, text = line.split(/ :/, 2)
          if text[0] == 1 and text[-1] == 1
            on_ctcp(from, to, text[1..-2])
          else
            on_msg(from, to, text)
          end
        when 'NOTICE' then
          to, text = line.split(/ :/, 2)
          if text[0] == 1 and text[-1] == 1
            on_ctcp_reply(from, to, text[1..-2])
          else
            on_notice(from, to, text)
          end
        when 'PING' then
          text = line.split(/.+ :/, 1)
          send_line("PONG #{text}")
        when 'MODE' then
          target, line = line.split(/ :?/, 2)
          params = line.split(/ /)
          flags = params.shift
          on_mode(from, target, flags, params)
        when 'TOPIC' then
          channel, text = line.split(/ :/, 2)
          on_topic(from, channel, text)
        when '331' then
          channel, text = line.split(/ :/, 2)
          on_rpl_notopic(channel.split(/ /).last, text)
        when '332' then
          channel, text = line.split(/ :/, 2)
          on_rpl_topic(channel.split(/ /).last, text)
        when '333'
          mynick, channel, nick, time = line.split(/ /, 4)
          on_rpl_topicinfo(channel, nick, time.to_i)
        when 'PART' then
          channel, reason = line.split(/ :/, 2)
          on_part(from, channel, reason)
        when 'JOIN' then
          on_join(from, line.sub(/^:/, ''))
        when 'QUIT' then
          on_quit(from, line.sub(/^:/, ''))
        when 'KICK' then
          line, reason = line.split(/ :/, 2)
          channel, nick = line.split(/ /, 2)
          on_kick(from, channel, nick, reason)
        when 'KILL' then
          nick, reason = line.split(/ :/, 2)
          on_kill(from, nick, reason)
        when 'NICK' then
          on_nick(from, line.sub(/^:/, ''))
        when '311' then
          line.scan(/^.+? (.+?) (.+?) (.+?) \* :(.+)$/) { |nick,user,host,realname|
            on_whoisuser(nick, user, host, realname)
          }
        when '312' then
          line.scan(/^.+? (.+?) (.+?) :(.+)$/) { |nick,server,serverinfo|
            on_whoisserver(nick, server, serverinfo)
          }
        when '317' then
          values, keys = line.split(/ :/)
          values = values.split(/ /)[1..-1]
          keys = keys.split(/, /)
          nick = values.shift
          info = {}
          keys.each_with_index { |key,i|
            info[key] = values[i]
          }
          on_whoisidle(nick, info)
        when '318' then
          nick, = line.split(/ :/, 2)
          on_endofwhois(nick.split(/ /).last)
        when '319' then
          nicks, channels = line.split(/ :/, 2)
          on_whoischannels(nicks.split(/ /).last, channels.split(/ /))
        when '375' then
          on_motdstart
        when '372' then
          text = line.split(/.+ :- /, 1)
          on_motd(from, text)
        when '376' then
          on_endofmotd
        when '422' then
          on_err_nomotd
        when '433' then
          on_err_nicknameinuse
        when '436' then # ERR_NICKCOLLISION
          on_err_nicknameinuse
        when '432' then
          on_err_erroneousnickname
        when '353' then
          channel, names = line.split(/ :/, 2)
          channel = channel.split(/ /).pop
          on_names(channel, names.split(/ /))
        when '366' then
          channel = line.split(/ /)[1]
          on_endofnames(channel)
        when '381' then
          on_youreoper
        when '475' then
          line, text = line.split(/ :/, 2)
          on_err_badchannelkey(line.split(/ /).last, text)
        when '482' then
          channel, msg = line.split(/ /, 2).last.split(/ :/, 2)
          on_chanoprivsneeded(channel, msg)
        when '004' then
          @servername, @serverversion, @usermodes, @channelmodes = line.split(/ /)
        when '005' then
          line, msg = line.split(/ :/, 2)
          features = {}
          line.split(/ /).each { |pair|
            k, v = pair.split(/=/, 2)
            features[k] = v
          }

          on_features(features, msg)
      end
    end

    def run
      loop {
        line = recv_line
        handle_line(line)
      }
    end
  end
end
