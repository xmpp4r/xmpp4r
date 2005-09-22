#!/usr/bin/ruby

# This script will request the version information of a list of JID given
# on stdin.

$:.unshift '../lib'

require 'optparse'
require 'xmpp4r/client'
require 'xmpp4r/iq/query/version'
include Jabber
#Jabber::debug = true

# settings
jid = JID::new('bot@localhost/Bot')
password = 'bot'

OptionParser::new do |opts|
  opts.banner = 'Usage: mass_sender.rb -j jid -p password'
  opts.separator ''
  opts.on('-j', '--jid JID', 'sets the jid') { |j| jid = JID::new(j) }
  opts.on('-p', '--password PASSWORD', 'sets the password') { |p| password = p }
  opts.on_tail('-h', '--help', 'Show this message') {
    puts opts
    exit
  }
  opts.parse!(ARGV)
end

cl = Client::new(jid, false)
cl.connect
cl.auth(password)
exit = false
sent = []
cl.add_iq_callback do |iq|
  if iq.type == :result and iq.query.class == IqQueryVersion
    r = [ iq.from.to_s, iq.query.iname, iq.query.version, iq.query.os ]
    puts r.inspect
  end
end
cl.send(Presence::new)
iq = Iq::new(:get)
iq.query = IqQueryVersion::new
STDIN.each_line do |l|
  l.chomp!
  iq.set_to(JID::new(l).to_s)
  cl.send(iq)
end
while not exit do
	cl.process
end
cl.close
