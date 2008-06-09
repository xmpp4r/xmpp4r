#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../../lib'

require 'test/unit'
require File::dirname(__FILE__) + '/../lib/clienttester'

require 'xmpp4r/xhtml'
include Jabber

class XHTML::HTMLTest < Test::Unit::TestCase
  def test_set
    contents1 = REXML::Element.new('p')
    contents1.text = 'Hello'
    html = XHTML::HTML.new(contents1)
    assert_kind_of(XHTML::Body, html.first_element('body'))
    assert_equal("<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml'><p>Hello</p></body></html>", html.to_s)

    contents2 = REXML::Element.new('a')
    contents2.attributes['href'] = 'about:blank'
    contents2.text = 'nothing'
    html.contents = ["Look at ", contents2]
    assert_equal("<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml'>Look at <a href='about:blank'>nothing</a></body></html>", html.to_s)
  end

  def test_parse
    html = XHTML::HTML.new('There is a fine <a href="http://home.gna.org/xmpp4r/">library</a>')
    assert_equal("<html xmlns='http://jabber.org/protocol/xhtml-im'><body xmlns='http://www.w3.org/1999/xhtml'>There is a fine <a href='http://home.gna.org/xmpp4r/'>library</a></body></html>", html.to_s)
  end

  def test_text
    a1 = REXML::Element.new('a')
    a1.attributes['href'] = 'http://www.jabber.org/'
    a1.text = 'Jabber'
    a2 = REXML::Element.new('a')
    a2.attributes['href'] = 'http://home.gna.org/xmpp4r/'
    a2.text = 'XMPP4R'
    html = XHTML::HTML.new(["Look at ", a1, " & ", a2])
    assert_equal("Look at Jabber & XMPP4R", html.to_text)
  end
end
