#!/usr/bin/ruby

# This script will send a jabber message to a list of JID given on stdin.

$:.unshift '../lib'

require 'optparse'
require 'xmpp4r'
include Jabber
#Jabber::DEBUG = true

# - message in file
# - subject in command line
# - JID list on stdin

# settings
jid = JID::new('bot@localhost/Bot')
password = 'bot'
filename = 'message.txt'

subject = "Message de test"

OptionParser::new do |opts|
  opts.banner = 'Usage: mass_sender.rb -j jid -p password'
  opts.separator ''
  opts.on('-j', '--jid JID', 'sets the jid') { |j| jid = JID::new(j) }
  opts.on('-p', '--password PASSWORD', 'sets the password') { |p| password = p }
  opts.on('-f', '--filename MESSAGE', 'sets the filename containing the message') { |f| filename = f }
  opts.on('-s', '--subject SUBJECT', 'sets the subject') { |s| subject = s }
  opts.on_tail('-h', '--help', 'Show this message') {
    puts opts
    exit
  }
  opts.parse!(ARGV)
end

body = IO::read(filename).chomp

cl = Client::new(jid, false)
cl.connect
cl.auth(password) or raise "Auth failed"
exit = false
cl.add_message_callback { |m|
  cl.send(Message::new(m.from, "Je suis un robot. Si tu souhaites contacter un administrateur du serveur, ecris a lucas@nussbaum.fr ."))
  if m.body == 'exitnowplease'
    cl.send(Message::new(m.from, "Exiting ..."))
    exit = true
  end
  cl.send(Message::new('lucas@nussbaum.fr', "From #{m.from}: #{m.body.to_s}"))
}
cl.send(Presence::new)
m = Message::new(nil, body)
STDIN.each_line { |l|
  l.chomp!
  m.set_to(JID::new(l).to_s)
  cl.send(m)
}
while not exit do
	cl.process(1)
end
cl.close
