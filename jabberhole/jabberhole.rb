#!/usr/bin/env ruby

require 'socket'
require 'thread'

require 'proxy'
require 'clientserver'


Jabber::debug = true

# Find user-scripts
Dir.new('scripts').each { |file|
  next if file =~ /^\./

  #require("scripts/#{file}")
}

# Open the proxy's server socket
server = TCPServer.new(5224)
server.listen(10)

# Main loop
loop {
  # Accept client connections
  client = server.accept
  # Generate a new proxy relaying client & server stanzas
  ClientServer.new(client)
}
