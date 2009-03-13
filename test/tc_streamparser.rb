#!/usr/bin/ruby

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r'
include Jabber

class MockListener
  attr_reader :received

  def receive(element)
    @received = element
  end

  def parse_failure(exception)
    raise exception
  end
end

class StreamParserTest < Test::Unit::TestCase
  STREAM = '<stream:stream xmlns:stream="http://etherx.jabber.org/streams">'

  def setup
    @listener = MockListener.new
  end

  def teardown
    @listener = nil
  end

  def parse_simple_helper(fixture)
    parser = StreamParser.new(STREAM + fixture, @listener)
    
    begin
      parser.parse
    rescue Jabber::ServerDisconnected => e
    end
    
    yield parse_with_rexml(fixture)
  end

  def parse_with_rexml(fixture)
    REXML::Document.new(fixture).root
  end

  def test_simple_text
    parse_simple_helper( "<a>text</a>" ) do |desired|
      assert_equal desired.name, @listener.received.name
      assert_equal desired.text, @listener.received.text
      assert_equal desired.cdatas, @listener.received.cdatas
    end
  end

  def test_simple_cdata
    parse_simple_helper( "<a><![CDATA[<cdata>]]></a>" ) do |desired|
      assert_equal desired.name, @listener.received.name
      assert_equal desired.text, @listener.received.text
      assert_equal desired.cdatas, @listener.received.cdatas
    end
  end

  def test_composite_text_cdata
    parse_simple_helper( "<a>text<![CDATA[<cdata>]]></a>" ) do |desired|
      assert_equal desired.name, @listener.received.name
      assert_equal desired.text, @listener.received.text
      assert_equal desired.cdatas, @listener.received.cdatas
    end
  end

  def test_composite_cdata_text
    parse_simple_helper( "<a><![CDATA[<cdata>]]>text</a>" ) do |desired|
      assert_equal desired.name, @listener.received.name
      assert_equal desired.text, @listener.received.text
      assert_equal desired.cdatas, @listener.received.cdatas
    end
  end

  def test_complex_composite_cdata_text
    parse_simple_helper( "<a><![CDATA[<cdata>]]>text<![CDATA[<cdata>]]>text</a>" ) do |desired|
      assert_equal desired.name, @listener.received.name
      assert_equal desired.text, @listener.received.text
      assert_equal desired.cdatas, @listener.received.cdatas
    end
  end

  def test_entity_escaping1
    parse_simple_helper( "<a>&apos;&amp;&quot;</a>" ) do |desired|
      assert_equal "'&\"", @listener.received.text
      assert_equal "<a>&apos;&amp;&quot;</a>", @listener.received.to_s
    end
  end

  def test_entity_escaping2
    parse_simple_helper( "<a>&amp;amp;amp;</a>" ) do |desired|
      assert_equal "&amp;amp;", @listener.received.text
      assert_equal "<a>&amp;amp;amp;</a>", @listener.received.to_s
    end
  end

=begin
  ##
  # FIXME:
  # http://www.germane-software.com/projects/rexml/ticket/165
  def test_unbound_prefix
    fixture = "<message><soe:instantMessage/></message>"
    parser = StreamParser.new(STREAM + fixture, @listener)

    assert_nothing_raised { parser.parse }
  end
=end

  def test_stream_restart
    parser = StreamParser.new(STREAM + "<stream:stream xmlns:stream='http://etherx.jabber.org/streams' to='foobar'>", @listener)

    begin
      parser.parse
    rescue Jabber::ServerDisconnected => e
    end
    
    assert_equal 'foobar', @listener.received.attributes['to']
  end
end
