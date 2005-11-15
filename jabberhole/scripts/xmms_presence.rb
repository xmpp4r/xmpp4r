#
# XMMS currently-playing status-message
# (Works with Beep-Media-Player, too)
#
# Substitutes all occurences of
# ${song}
# with the song name currently played in your
# status message.
#


require 'xmms'

presences = {}
current_song = ''

# Add a callback for stanzas from client to server
Proxy.add_client_callback { |stanza,cl|
  if stanza.kind_of?(Jabber::Presence)
    puts "Broadcasting presence for #{cl.jid}"

    presences[cl] = stanza

    send_presence(current_song, cl, stanza)
    true
  else
    false
  end
}

Thread.new { loop {
  xr = Xmms::Remote.new
  song = xr.playlist[xr.playlist_pos][0]
  if song != current_song
    puts "Song has changed: #{current_song.inspect} -> #{song}"
    current_song = song
    presences.each { |stream,pres|
      send_presence(current_song, stream, pres)
    }
  end

  sleep 1
} }

def send_presence(song, stream, orig_presence)
  pres = Jabber::Presence.new.import(orig_presence)
  p pres.status
  pres.status = pres.status.gsub(/\$\{song\}/, song)
  p pres.status
  puts "Broadcasting presence for #{stream.jid}"
  stream.server_conn.send(pres)
  pres.from = stream.jid
  stream.send(pres)
end
