#!/usr/bin/ruby

$:.unshift '../lib'

require 'xmpp4r'
require 'xmpp4r/roster'

# Command line argument checking

if ARGV.size != 2
  puts("Usage: ./rosterwatch.rb <jid> <password>")
  exit
end

# Building up the connection

jid = Jabber::JID.new(ARGV[0])

cl = Jabber::Client.new(jid, false)
cl.connect
cl.auth(ARGV[1]) or raise "Auth failed"

# The roster instance

roster = Jabber::Roster.new

# <iq/> callback to feed the roster instance
# and output the roster afterwards

cl.add_iq_callback { |iq|
  roster.receive_iq(iq)
  if (iq.type == 'result') && (iq.queryns == 'jabber:iq:roster')
    roster.each { |item|
      puts "#{item.jid} (#{item.iname.inspect}, #{item.subscription}): #{item.groups.join(', ')}"
    }
    puts "Roster size: #{roster.to_a.size}"
  end
}

# <presence/> callback which looks up the
# nickname from the roster

cl.add_presence_callback { |pres|
  item = roster[pres.from]
  unless item.nil?
    puts "#{item.iname} (#{pres.from}) #{pres.show} (#{pres.priority.to_s}): #{pres.status.inspect}"
  else
    # Probably only your other resources
    puts "Not in roster: #{pres.from} #{pres.show} (#{pres.priority.to_s}): #{pres.status.inspect}"
  end
}

# Send request for roster
cl.send(Jabber::Iq.new_rosterget)
# Send initial presence
# This is important as it ensures reception of
# further <presence/> stanzas
cl.send(Jabber::Presence.new.set_show('dnd').set_status('Watching my roster change...').set_priority(-127))

loop do
  cl.process
  sleep(1)
end

cl.close
