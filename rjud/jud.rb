#!/usr/bin/ruby

require 'judconfig'
require "mysql"
require 'date'
require 'xmpp4r'
require 'xmpp4r/component'
require 'xmpp4r/iq/query/discoitems'
require 'xmpp4r/iq/query/discoinfo'
include Jabber
Thread::abort_on_exception = true

# TODO list
# - add helpers for browsing and use them.

# Debug function
def dputs(s)
  puts Time::now.to_s + ": " + s + " (#{caller(1)[0]})"
end

def memstats
  puts "---------------"
  GC.start
  d = Hash::new(0)
  ObjectSpace.each_object { |o| d[o.class] += 1 }
  d2 = d.to_a.sort { |a, b| b[1] <=> a[1] }
  d2[0..15].each { |l| puts "#{l[1]} #{l[0]}" }
end

# jabber:iq:browse handling
def sendbrowsereply(conn, from, id)
  dputs "Sending jabber:iq:browse reply to #{from}"
  i = Iq::new_query(:result, from)
  i.from = JUDNAME
  i.id = id
  i.query.add_namespace('jabber:iq:browse')
  i.query.add_attribute('category', 'service')
  i.query.add_attribute('type', 'jud')
  i.query.add_attribute('jid', JUDNAME)
  i.query.add_attribute('name', 'Jabber User Directory')
  i.query.add(REXML::Element::new('ns').add_text('jabber:iq:search'))
  i.query.add(REXML::Element::new('ns').add_text('jabber:iq:register'))
  conn.send(i)
end

# Disco handling
def senddiscoreplyinfo(conn, from, id)
  dputs "Sending disco#info reply to #{from}"
  i = Iq::new(:result, from)
  i.from = JUDNAME
  i.id = id
  i.query = IqQueryDiscoInfo::new
  i.query.add(DiscoIdentity::new('directory', nil, 'user'))
  i.query.add(DiscoFeature::new('jabber:iq:search'))
  i.query.add(DiscoFeature::new('jabber:iq:register'))
  conn.send(i)
end

def senddiscoreplyitems(conn, from, id)
  dputs "Sending disco#items reply to #{from}"
  i = Iq::new_query(:error, from)
  i.from = JUDNAME
  i.id = id
  i.query = IqQueryDiscoItems::new
  error = Error::new("bad-request").set_code(400).set_type(:modify)
  i.query.add(error)
  conn.send(i)
end

# jabber:iq:search
def handlesearch(conn, iq)
  if iq.type == :get
    dputs "Sending jabber:iq:search type=get reply to #{iq.from}"
    # return search fields
    i = Iq::new_query(:result, iq.from)
    i.from = JUDNAME
    i.id = iq.id
    i.query.add_namespace('jabber:iq:search')
    i.query.add(REXML::Element::new('instructions').add_text("Use the enclosed form to search. You client might not support x:data. Consider using the web interface at #{WEBINTERFACE}"))
    # create the form
    x = REXML::Element::new('x')
    x.add_namespace('jabber:x:data')
    x.add_attribute('type', 'form')
    x.add(REXML::Element::new('title').add_text("Search users in #{JUDNAME}"))
    x.add(REXML::Element::new('instructions').add_text('Fill in the form to search for any matching Jabber User'))
    [ # var, label, type
      [ 'jid', 'Jabber ID', 'text-single' ],
      [ 'first', 'Firstname', 'text-single' ],
      [ 'last', 'Lastname', 'text-single' ],
      [ 'nick', 'Nickname', 'text-single' ],
      [ 'email', 'Email address', 'text-single' ],
      [ 'website', 'Website', 'text-single' ],
      [ 'location', 'Location', 'text-single' ],
      [ 'birthdate', 'Birthdate (DD/MM/YYYY)', 'text-single' ]
    ].each do |f|
      e = REXML::Element::new('field')
      e.add_attribute('var', f[0])
      e.add_attribute('label', f[1])
      e.add_attribute('type', f[2])
      x.add(e)
    end
    e = REXML::Element::new('field')
    e.add_attribute('var', 'gender')
    e.add_attribute('label', 'Gender (M/F)')
    e.add_attribute('type', 'list-single')
    o = REXML::Element::new('option')
    o.add_attribute('label', 'Male')
    o.add(REXML::Element::new('value').add_text('M'))
    e.add(o)
    o = REXML::Element::new('option')
    o.add_attribute('label', 'Female')
    o.add(REXML::Element::new('value').add_text('F'))
    e.add(o)
    x.add(e)
    i.query.add(x)
    conn.send(i)
  elsif iq.type == :set
    dputs "Got a jabber:iq:search query from #{iq.from}"
    fields = {}
    x = nil
    iq.query.each_element('x') { |e| x = e if x.nil? }
    type = 'simple'
    if x
      dputs "Query was using jabber:x:data."
      type = 'xdata'
      # We have an 'x' element.
      x.each_element('field') do |e|
        v = e.attribute('var')
        next if v.nil?
        v = v.value
        next if v == 'FORM_TYPE'
        value = nil
        e.each_element('value') { |e2| value = e2 if value.nil? }
        t = value.text
        next if t.nil? or t == ''
        fields[v] = t
      end
    else
      # We don't have an 'x' element
      iq.query.each_element do |e|
        next if e.text.nil? or e.text == ''
        fields[e.name] = e.text
      end
    end
    # fields is set. Let's build the query.
    i = Iq::new(:result, iq.from)
    i.from = JUDNAME
    i.id = iq.id
    queryandreply(conn, i, fields, type)
  end
end

# jabber:iq:register
def handleregister(conn, iq)
  if iq.type == :get
    dputs "Sending jabber:iq:register type=get reply to #{iq.from}"
    # return search fields
    i = Iq::new_query(:result, iq.from)
    i.from = JUDNAME
    i.id = iq.id
    i.query.add_namespace('jabber:iq:register')
    i.query.add(REXML::Element::new('instructions').add_text("Use the enclosed form to register. You client might not support x:data. Consider using the web interface at #{WEBINTERFACE}"))
    # create the form
    x = REXML::Element::new('x')
    x.add_namespace('jabber:x:data')
    x.add_attribute('type', 'form')
    x.add(REXML::Element::new('title').add_text("Jabber User Directory Registration"))
    x.add(REXML::Element::new('instructions').add_text('Fill in the form to register in the Jabber User Directory'))
    [ # var, label, type
      [ 'first', 'Firstname', 'text-single' ],
      [ 'last', 'Lastname', 'text-single' ],
      [ 'nick', 'Nickname', 'text-single' ],
      [ 'email', 'Email address', 'text-single' ],
      [ 'website', 'Website', 'text-single' ],
      [ 'location', 'Location', 'text-single' ],
      [ 'birthdate', 'Birthdate (DD/MM/YYYY)', 'text-single' ],
      [ 'comment', 'Comments', 'text-single' ]
    ].each do |f|
      e = REXML::Element::new('field')
      e.add_attribute('var', f[0])
      e.add_attribute('label', f[1])
      e.add_attribute('type', f[2])
      x.add(e)
    end
    e = REXML::Element::new('field')
    e.add_attribute('var', 'gender')
    e.add_attribute('label', 'Gender (M/F)')
    e.add_attribute('type', 'list-single')
    o = REXML::Element::new('option')
    o.add_attribute('label', 'Male')
    o.add(REXML::Element::new('value').add_text('M'))
    e.add(o)
    o = REXML::Element::new('option')
    o.add_attribute('label', 'Female')
    o.add(REXML::Element::new('value').add_text('F'))
    e.add(o)
    x.add(e)
    i.query.add(x)
    conn.send(i)
  elsif iq.type == :set
    dputs "Got a jabber:iq:register query from #{iq.from}"
    fields = {}
    x = nil
    iq.query.each_element('x') { |e| x = e if x.nil? }
    if x
      dputs "Query was using jabber:x:data."
      # We have an 'x' element.
      x.each_element('field') do |e|
        v = e.attribute('var')
        next if v.nil?
        v = v.value
        next if v == 'FORM_TYPE'
        value = nil
        e.each_element('value') { |e2| value = e2 if value.nil? }
        t = value.text
        next if t.nil? or t == ''
        fields[v] = t
      end
    else
      # We don't have an 'x' element
      iq.query.each_element do |e|
        next if e.text.nil? or e.text == ''
        fields[e.name] = e.text
      end
    end
    # fields is set. Let's build the query.
    i = Iq::new(:result, iq.from)
    i.from = JUDNAME
    i.id = iq.id
    registerandreply(conn, i, JID::new(iq.from).strip, fields)
  end
end

# Query the database for the given fields and send the reply
def queryandreply(jabconnection, iq, fields, type)
  begin
    dbh = Mysql::real_connect(MYSQLHOST, MYSQLUSER, MYSQLPASS, MYSQLDB)
    # delete data
    query = "SELECT jid, first, last, nick, email, website, location, comment, gender, birthdate FROM jud WHERE TRUE"
    # normal fields
    ['jid', 'first', 'last', 'nick', 'email', 'website', 'location', 'comment'].each do |f|
      if fields[f]
        query += " AND #{f} LIKE '%#{Mysql::quote(fields[f])}%'"
      end
    end
    # gender
    if fields['gender'] and (fields['gender'].upcase == 'M' or fields['gender'].upcase == 'F')
      query += " AND gender = '#{fields['gender'].upcase}'"
    end
    # birthdate
    if (b = fields['birthdate'])
      begin
        d = Date::strptime(b, '%d/%m/%Y')
        query += " AND birthdate = '#{d.to_s}'"
      rescue
      end
    end
    if MYSQLLIMIT > 0
      query += " LIMIT #{MYSQLLIMIT}"
    end
    dputs "MySQL Query: #{query}"
    res = dbh.query(query)
    q = REXML::Element::new('query')
    q.add_namespace('jabber:iq:search')
    iq.add(q)
    if type == 'simple'
      res.each_hash do |r|
        i = REXML::Element::new('item')
        i.add_attribute('jid', r['jid'] || '')
        [ 'first', 'last', 'nick', 'email' ].each do |f|
          e = REXML::Element::new(f)
          e.add_text(r[f] || '')
          i.add(e)
        end
        q.add(i)
      end
    elsif type == 'xdata'
      x = REXML::Element::new('x')
      q.add(x)
      x.add_namespace('jabber:x:data')
      x.add_attribute('type', 'result')
      f = REXML::Element::new('field')
      f.add_attribute('type', 'hidden')
      f.add_attribute('var', 'FORM_TYPE')
      f.add(REXML::Element::new('value').add_text('jabber:iq:search'))
      x.add(f)
      r = REXML::Element::new('reported')
      x.add(r)
      fields = [ # var, label, type
        [ 'jid', 'Jabber ID', 'text-single' ],
        [ 'first', 'Firstname', 'text-single' ],
        [ 'last', 'Lastname', 'text-single' ],
        [ 'nick', 'Nickname', 'text-single' ],
        [ 'email', 'Email address', 'text-single' ],
        [ 'website', 'Website', 'text-single' ],
        [ 'location', 'Location', 'text-single' ],
        [ 'birthdate', 'Birthdate', 'text-single' ],
        [ 'comment', 'Comments', 'text-single' ]
      ]
      fields.each do |f|
        e = REXML::Element::new('field')
        e.add_attribute('var', f[0])
        e.add_attribute('label', f[1])
        r.add(e)
      end
      res.each_hash do |r|
        i = REXML::Element::new('item')
        fields.each do |fi|
          f = REXML::Element::new('field')
          f.add_attribute('var', fi[0])
          f.add(REXML::Element::new('value').add_text(r[fi[0]] || ''))
          i.add(f)
        end
        x.add(i)
      end
    else
		 raise "Type unknown: #{type}"
    end
    jabconnection.send(iq)
    res.free
  rescue MysqlError => e
    dputs "MySQL Error code: #{e.errno}"
    dputs "MySQL Error message: #{e.error}"
    e = REXML::Element::new('error')
    e.add_attribute('code', '500')
    e.add_attribute('type', 'wait')
    na = REXML::Element::new('internal-server-error')
    na.add_namespace('urn:ietf:params:xml:ns:xmpp-stanzas')
    e.add(na)
    iq2 = Iq::new(:error, iq.to)
    iq2.from = JUDNAME
    iq2.id = iq.id
    iq2.add(e)
    jabconnection.send(iq2)
  ensure
    dbh.close if dbh
  end
end

# Register the user in the database and send the reply
def registerandreply(jabconnection, iq, jid, ifields)
  dputs "Registering user #{jid}"
  begin
    dbh = Mysql::real_connect(MYSQLHOST, MYSQLUSER, MYSQLPASS, MYSQLDB)
    # delete data
    q = "DELETE FROM jud WHERE jid = '#{jid}'"
    dputs "MySQL Query: #{q}"
    dbh.query(q)
    fields = {}
    # normal fields
    ['jid', 'first', 'last', 'nick', 'email', 'website', 'location', 'comment'].each do |f|
      if ifields[f]
        fields[f] = Mysql::quote(ifields[f])
      end
    end
    # gender
    if ifields['gender'] and (ifields['gender'].upcase == 'M' or ifields['gender'].upcase == 'F')
      fields['gender'] = ifields['gender'].upcase
    end
    # birthdate
    if (b = ifields['birthdate'])
      begin
        d = Date::strptime(b, '%d/%m/%Y')
        fields['birthdate'] = d.to_s
      rescue
      end
    end
    # let's build the query
    q1 = "INSERT INTO jud (jid, update_jid, update_ts"
    q2 = ") VALUES ('" + Mysql::quote(jid.to_s) + "', '" + Mysql::quote(iq.to.to_s) + "', NOW()"
    fields.each do |k, v|
      q1 += ", #{k}"
      q2 += ", '#{v}'"
    end
    q = q1 + q2 + ')'
    if fields.length > 0
      dputs "MySQL Query: #{q}"
      dbh.query(q)
    end
    jabconnection.send(iq)
  rescue MysqlError => e
    dputs "MySQL Error code: #{e.errno}"
    dputs "MySQL Error message: #{e.error}"
    e = REXML::Element::new('error')
    e.add_attribute('code', '500')
    e.add_attribute('type', 'wait')
    na = REXML::Element::new('internal-server-error')
    na.add_namespace('urn:ietf:params:xml:ns:xmpp-stanzas')
    e.add(na)
    iq.type = :error
    iq.add(e)
    jabconnection.send(iq)
  ensure
    dbh.close if dbh
  end
end

# connect & auth
c = Component::new(JUDNAME)
c.connect(ROUTERHOST, ROUTERPORT)
# register the callback for Iq requests
c.add_iq_callback do |i|
  if i.type == :get
    case i.queryns
      when 'jabber:iq:browse'
        sendbrowsereply(c, i.from, i.id)
      when 'http://jabber.org/protocol/disco#info'
        senddiscoreplyinfo(c, i.from, i.id)
      when 'http://jabber.org/protocol/disco#items'
        senddiscoreplyitems(c, i.from, i.id)
      when 'jabber:iq:search'
        handlesearch(c, i)
      when 'jabber:iq:register'
        handleregister(c, i)
      else
        dputs "Unhandled get NS: #{i.queryns}"
    end
  elsif i.type == :set
    case i.queryns
      when 'http://jabber.org/protocol/disco#info'
        senddiscoreplyinfo(c, i.from, i.id)
      when 'jabber:iq:search'
        handlesearch(c, i)
      when 'jabber:iq:register'
        handleregister(c, i)
      else
        dputs "Unhandled set NS: #{i.queryns}"
    end
  else
    dputs "Unhandled Iq type: #{i.type}"
  end
  true # consume
end
c.auth(ROUTERPASSWORD)
dputs "JUD started and connected to the router."
Thread.stop
