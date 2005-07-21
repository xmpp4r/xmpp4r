#!/usr/bin/ruby

$:.unshift '../lib'

require 'xmpp4r'
include Jabber

class BasicClient
  def initialize
    print "Welcome to this Basic Console Jabber Client!\n"
    quit = false
    # main loop
    while not quit do
      print "> "
      $defout.flush
      line = gets
      quit = true if line.nil?
      if not quit
        command, args = line.split(' ', 2)
        args.chomp!
        # main case
        case command
        when 'exit'
          quit = true
        when 'connect'
          do_connect(args)
        when 'auth'
          do_auth
        else
          print "Command \"#{command}\" unknown\n"
        end
      end
    end
    print "Goodbye!\n"
  end

  def do_help
    print "exit\n"
    print "connect\n"
    print "auth\n"
  end

  ##
  # connect <jid> <password>
  def do_connect(args)
    @jid, @password = args.split(' ', 3)
    @jid = JID::new(@jid)
    @cl = Client::new(@jid)
    @cl.connect
  end

  def do_auth
    @cl.auth(@password)
  end

  ##
  # register <email>
  def do_register(args)
    @cl.register(@password, args)
  end
end

BasicClient::new
