#!/usr/bin/ruby

$:.unshift '../lib'

require 'tempfile'
require 'test/unit'
require 'socket'
require 'xmpp4r/streamparser'
require 'xmpp4r/semaphore'
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

    parser.parse

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
  **********
  * FIXME! *
  **********

  def test_unbound_prefix
    parse_simple_helper("<message><soe:instantMessage/></message>") do |desired|
      assert_equal desired.first_element('*').name, 'instantMessage'
    end
  end
=end
end
