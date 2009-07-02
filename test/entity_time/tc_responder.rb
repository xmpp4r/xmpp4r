#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r/entity_time/responder'
include Jabber

class EntityTime::ResponderTest < Test::Unit::TestCase
  include ClientTester

  def a_utc_time
    Time.utc(2000,"jan",1,20,15,1) # xmlschema = "2000-01-01T20:15:01Z"
  end

  def test_entity_time_iq
    el_time = EntityTime::IqTime.new(a_utc_time)

    assert_equal('time', el_time.name, "element has wrong name")
    assert_equal('urn:xmpp:time', el_time.namespace, "element has wrong namespace")

    assert(el_time.elements["utc"], "element does not have a utc child")
    assert_equal('2000-01-01T20:15:01Z', el_time.elements["utc"].text, "element/utc has the wrong text")

    assert(el_time.elements["tzo"], "element does not have a tzo child")
    assert_equal("+00:00", el_time.elements["tzo"].text, "element/tzo has the wrong time zone offset")
  end

=begin
   http://xmpp.org/extensions/xep-0202.html
   <iq type='get'
       from='romeo@montague.net/orchard'
       to='juliet@capulet.com/balcony'
       id='time_1'>
     <time xmlns='urn:xmpp:time'/>
   </iq>
=end
  def test_query
    EntityTime::Responder.new(@client)

    iq = Iq.new(:get)
    t = REXML::Element.new('time')
    t.add_namespace('urn:xmpp:time')
    iq.add_element(t)

    reply = @server.send_with_id(iq)

    assert_equal(:result, reply.type)
    assert_equal('time', reply[0].name)
    assert_equal('urn:xmpp:time', reply[0].namespace)

    assert(reply[0].elements["utc"].has_text?, "element must have a utc time (actual time should be check here)")

    tmp = Time.now
    local_offset = Time.now.utc_offset
    hour_offset = local_offset / 3600
    min_offset = local_offset % 60
    offset = "%+03d:%02d"%[hour_offset, min_offset]

    assert_equal(offset, reply[0].elements["tzo"].text, "element should has an incorrect time zone offset")
  end

end
