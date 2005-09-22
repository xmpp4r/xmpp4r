#!/usr/bin/ruby

require 'xmpp4r/client'
require 'xmpp4r/helpers/roster'
require 'socket'
require 'ragde-config'
require 'thread'
include Jabber
Thread::abort_on_exception = true

Jabber::debug = true

class Ragde
  def initialize(myjid, mypw)
    jid = Jabber::JID::new(myjid)
    @myjid = Jabber::JID::new(jid.node, jid.domain, 'Ragde')
    @cl = Jabber::Client::new(@myjid)
    @cl.connect
    @cl.auth(mypw)
    @cl.send(Presence::new)
    @roster = Jabber::Helpers::Roster::new(@cl)
    @server = TCPServer::new(12346)
    @server.listen(10)
  end

  def accept
    while true do
      s2 = @server.accept
      handle_req(s2)
    end
  end

  def handle_req(s)
    j = JID::new(s.gets.chomp)
    a = @roster.find(j)
    p a
    l = []
    a.each_pair do |k, v|
      l << [k, v]
    end
    l.sort! do |a, b|
      b[1] <=> b[0]
    end
    s.puts "#{l[0]}"
    s.close
  end
end

ragde = Ragde::new(RAGDE_JID, RAGDE_PASSWORD)
ragde.accept




