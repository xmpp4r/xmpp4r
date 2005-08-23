#!/usr/bin/ruby

$:.unshift '../lib'

require 'xmpp4r'
require 'xmpp4r/rosterquery'

# Command line argument checking

if ARGV.size < 4
  puts("Usage: ./rosterrename.rb <your jid> <password> <jid to rename> <new name> [<group1> ... <groupn>]")
  exit
end

# Building up the connection

#Jabber::DEBUG = true

jid = Jabber::JID.new(ARGV[0])

cl = Jabber::Client.new(jid, false)
cl.connect
cl.auth(ARGV[1]) or raise "Auth failed"

# The iq stanza
iq = Jabber::Iq::new(:set)
# The new roster instance and item element
iq.add(Jabber::RosterQuery.new).add(Jabber::RosterItem.new(ARGV[2], ARGV[3])).groups = ARGV[4..ARGV.size]

# Sending the stanza
cl.send(iq)

# Don't look at the results:
cl.close
