#!/usr/bin/env ruby

require 'xmpp4r'
require 'xmpp4r/helpers/mucbrowser'

muc_jid = Jabber::JID.new(ARGV.shift)

cl = Jabber::Client.new(Jabber::JID.new('collector@jabber.ccc.de/mucbrowser'))
cl.connect
cl.auth('traversal')

browser = Jabber::Helpers::MUCBrowser.new(cl)

print "Querying #{muc_jid} for identity..."; $stdout.flush
name = browser.muc_name(muc_jid)

if name.nil?
  puts " Sorry, but the queried MUC component doesn't seem to support MUC or Groupchat."
else
  puts " #{name}"
  
  print "Querying #{muc_jid} for its rooms..."; $stdout.flush
  rooms = browser.muc_rooms(muc_jid)
  puts " #{rooms.size} rooms found"

  max_room_length = 0
  rooms.each_key { |jid| max_room_length = jid.to_s.size if jid.to_s.size > max_room_length }

  rooms.each { |jid,name|
    puts "#{jid.to_s.ljust(max_room_length)} #{name}"
  }
end

cl.close
