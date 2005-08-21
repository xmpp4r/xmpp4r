#!/usr/bin/ruby
#
# XMPP4R - XMPP Library for Ruby
# Copyright (C) 2005 Stephan Maka <stephan@spaceboyz.net>
# Released under GPL v2 or later
#
#
# Roster-Watch example
#
#
# Learn how a roster looks like
#       how presences are received
#       what vCards contain
#
# It's recommended to insert 'p' commands in this script. :-)
#
# This script does:
#
# * Listing roster changes
#
# * Requesting vCards for items in your roster
#
# * Receiving vCards and saving a <NICKNAME/> or <FN/> from it
#
# * Listing presence changes
#

$:.unshift '../lib'

require 'xmpp4r'
require 'xmpp4r/roster'

# Command line argument checking

if ARGV.size != 2
  puts("Usage: ./rosterwatch.rb <jid> <password>")
  exit
end

# Building up the connection

#Jabber::DEBUG = true

jid = Jabber::JID.new(ARGV[0])

cl = Jabber::Client.new(jid, false)
cl.connect
cl.auth(ARGV[1]) or raise "Auth failed"


# The roster instance
roster = Jabber::Roster.new(cl, Jabber::Presence.new.set_show('dnd').set_status('Watching my roster change...'))


# What has changed in the roster?
#
# Mostly only called back once,
# except another resource is renaming items etc.
roster.add_rosteritem_callback { |change|
  oitem = change.old
  item = change.cur
  
  if oitem.nil?
    # We didn't knew before:
    puts("#{item.iname} (#{item.jid}, #{item.subscription}) #{item.groups.join(', ')}")
  else
    # Showing whats different:
    puts("#{oitem.iname} (#{oitem.jid}, #{oitem.subscription}) #{oitem.groups.join(', ')} -> #{item.iname} (#{item.jid}, #{item.subscription}) #{item.groups.join(', ')}")
  end

  # Don't we have a vCard from him?
  unless roster.vcards[item.jid]
    # Request a vCard from him!
    roster.request_vcard(item.jid)
  end
}

# Received a vCard...
#
# We set RosterItem's name here to remember it, the item is *not* sent!
roster.add_vcard_callback { |iq|
  print("Got vCard for #{iq.from}: ")
  
  # Do we have that in the roster?
  item = roster[iq.from.strip]
  if item
    if iq.vcard.element('NICKNAME')
      # Let's take the <NICKNAME/>
      item.iname = iq.vcard.element('NICKNAME').text
      puts("NICKNAME = #{item.iname.inspect}")
    elsif iq.vcard.element('FN')
      # Let's take the <FN/>
      item.iname = iq.vcard.element('FN').text
      puts("FN = #{item.iname.inspect}")
    else
      # Somebody was lazy here
      puts("but no name given in vCard")
    end
  else
    # vCards are only requested for items in the roster here...
    puts("but #{iq.from} is not in roster. Who requested the vCard?")
  end
}

# <presence/> callback
roster.add_presence_callback { |change|
  # Can't look for something that just does not exist...
  if change.old.nil?
    # ...so create it:
    change.old = Jabber::Presence.new
  end
  
  # Print name and jid:
  name = change.cur.from
  if roster[change.cur.from.strip] && roster[change.cur.from.strip].iname
    name = "#{roster[change.cur.from.strip].iname} (#{change.cur.from})"
  end
  puts(name)

  # Print type changes:
  unless change.old.type.nil? && change.cur.type.nil?
    puts("  Type: #{change.old.type.inspect} -> #{change.cur.type.inspect}")
  end
  # Print show changes:
  unless change.old.show.nil? && change.cur.show.nil?
    puts("  Show:     #{change.old.show.to_s.inspect} -> #{change.cur.show.to_s.inspect}")
  end
  # Print status changes:
  unless change.old.status.nil? && change.cur.status.nil?
    puts("  Status:   #{change.old.status.to_s.inspect} -> #{change.cur.status.to_s.inspect}")
  end
  # Print priority changes:
  unless change.old.priority.nil? && change.cur.priority.nil?
    puts("  Priority: #{change.old.priority.inspect} -> #{change.cur.priority.inspect}")
  end
}

# Main loop:

loop do
  cl.process
  sleep(1)
end

cl.close

