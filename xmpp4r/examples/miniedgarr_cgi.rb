#!/usr/bin/env ruby -w

$:.unshift '../lib'

require 'GD'
require 'cgi'
require 'digest/md5'
        
require 'rexml/document'

require 'xmpp4r'
require 'xmpp4r/rosterquery'

# Handle CGI parameters
cgi = CGI.new
jid = Jabber::JID.new(cgi['jid']).strip
jidhash = cgi['hash']
transparency = (cgi['transparency'] == 'true')

# Create data

roster = Jabber::RosterQuery.new
presences = {}

# Load state

doc = REXML::Document.new(File.new('edgarrstate.xml'))

doc.root.each_element { |e|
  if (e.name == 'query') && (e.namespace == 'jabber:iq:roster')
    # TODO: Get RosterItem's name
    roster.import(e)
  elsif e.name == 'presence'
    pres = Jabber::Presence.new.import(e)

    if (pres.from.strip == jid) || (Digest::MD5.new(pres.from.strip.to_s).to_s == jidhash)
      if (jid == '') && !jidhash.nil?
        jid = pres.from.strip
      end
      presences[pres.from] = pres
    end
  end
}

resources = (presences.size < 1) ? 1 : presences.size

# Paint the image

im = GD::Image.new(200, resources * 34 + 18)

white = im.colorAllocate(255,255,255)
black = im.colorAllocate(0,0,0)       

# make the background transparent and interlaced
if transparency
  im.transparent(white)
else
  im.fill(0, 0, white)
end
im.interlace = true

# Put a black frame around the picture
im.rectangle(0,0,199,resources * 34 + 17,black)

# Put JID at top
im.string(GD::Font::MediumFont, 3, 3, jid.to_s, black)

if (presences.size < 1)
  im.string(GD::Font::SmallFont, 3, 18, 'Unavailable', black)
else
  y = 18
  presences.each { |jid,pres|
    im.string(GD::Font::SmallFont, 3, y, pres.from.resource, black)
    y += 14

    show = pres.show.to_s
    if pres.type == :unavailable
      show = 'Offline'
    elsif pres.show.nil?
      show = 'Online'
    end
    im.string(GD::Font::TinyFont, 3, y, show, black)
    y += 9

    im.string(GD::Font::TinyFont, 3, y, pres.status.to_s, black)
    y += 11
  }
end

# Convert the image to PNG and print it on standard output
print "Content-type: image/png\n\n"
im.png STDOUT
