#!/usr/bin/ruby

# This bot will reply to every message it receives. To end the game, send 'exit'
# THREADED VERSION

$:.unshift '../lib'

require 'thread'
require 'xmpp4r'
include Jabber

# settings
myJID = JID::new('bot@localhost/Bot')
myPassword = 'bot'
cl = Client::new(myJID)
cl.connect
cl.auth(myPassword) or raise "Auth failed"
puts "Connected ! send messages to #{myJID.strip.to_s}."
mainthread = Thread.current
cl.add_message_callback { |m|
  cl.send(Message::new(m.from, "You sent: #{m.body}"))
  if m.body == 'exit'
    cl.send(Message::new(m.from, "Exiting ..."))
    mainthread.wakeup
  end
}
Thread.stop
cl.close
