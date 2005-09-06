#!/usr/bin/ruby

# This script can get all roster entries

require 'optparse'
require 'xmpp4r'
require 'xmpp4r/iq/query/roster'
include Jabber

get = true
jid = JID::new('lucastest@linux.ensimag.fr/rosterget')
password = 'lucastest'

OptionParser::new do |opts|
  opts.banner = 'Usage: roster.rb -t get -j jid -p password'
  opts.separator ''
  opts.on('-t', '--type get|set', 'sets the type of request') { |s| get = ( s == 'get' ? true : false) }
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
cl.send(Iq::new_rosterget)
exit = false
cl.add_iq_callback { |i|
  if i.type == :result and i.query.kind_of?(IqQueryRoster)
    i.query.each_element { |e|
      e.text = ''
      puts e.to_s
    }
    exit = true
  end
}
while not exit
  cl.process
end
cl.close
