#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'socket'
require 'xmpp4r/rexmladdons'
require 'xmpp4r/message'
require 'xmpp4r/errors'
include Jabber

class MessageTest < Test::Unit::TestCase
  def test_create
    x = Message.new()
    assert_equal("message", x.name)
    assert_equal("jabber:client", x.namespace)
    assert_equal(nil, x.to)
    assert_equal(nil, x.body)

    x = Message.new("lucas@linux.ensimag.fr", "coucou")
    assert_equal("message", x.name)
    assert_equal("lucas@linux.ensimag.fr", x.to.to_s)
    assert_equal("coucou", x.body)
  end

  def test_import
    x = Message.new
    assert_kind_of(REXML::Element, x.typed_add(REXML::Element.new('thread')))
    assert_kind_of(X, x.typed_add(REXML::Element.new('x')))
    assert_kind_of(X, x.x)
  end

  def test_type
    x = Message.new
    assert_equal(nil, x.type)
    x.type = :chat
    assert_equal(:chat, x.type)
    assert_equal(x, x.set_type(:error))
    assert_equal(:error, x.type)
    x.type = :groupchat
    assert_equal(:groupchat, x.type)
    x.type = :headline
    assert_equal(:headline, x.type)
    x.type = :normal
    assert_equal(:normal, x.type)
    x.type = :invalid
    assert_equal(nil, x.type)
  end

  def test_should_update_body
    x = Message.new()
    assert_equal(nil, x.body)
    assert_equal(x, x.set_body("trezrze ezfrezr ezr zer ezr ezrezrez ezr z"))
    assert_equal("trezrze ezfrezr ezr zer ezr ezrezrez ezr z", x.body)
    x.body = "2"
    assert_equal("2", x.body)
  end

  def test_should_update_xhtml_body
    x = Message.new()
    assert_equal(nil, x.xhtml_body)
    assert_equal(x, x.set_xhtml_body("check this <a href='domain.com'>link</a> out"))
    assert_equal("check this <a href='domain.com'>link</a> out", x.xhtml_body)
    x.xhtml_body = "2"
    assert_equal("2", x.xhtml_body)
  end

  def test_should_get_bodies
    x = Message.new()

    x.set_body("check this link <domain.com> out")
    assert_equal("check this link <domain.com> out", x.body)
    
    x.set_xhtml_body("<span style='font-weight: bold'>check <i>this</i> <a href='domain.com'>link</a> out</span>")
    assert_equal("<span style='font-weight: bold'>check <i>this</i> <a href='domain.com'>link</a> out</span>", x.xhtml_body)
    
    x.first_element("html").remove
    assert_equal(nil, x.xhtml_body)
    
    # Some clients send markupped body without <html/> wrapper,
    # and we need to be able to deal with this also
    el = REXML::Element.new("body")
    el.add_namespace("http://www.w3.org/1999/xhtml")
    el.add_text("xhtml body without wrapper")
    x.add_element(el)
    assert_equal("xhtml body without wrapper", x.xhtml_body)
  end
  
  def test_should_get_xhtml_body_of_new_message
    x = Message.new()
    
    x.set_xhtml_body("check <i>this</i> <a href='domain.com'>link</a> out")
    assert_equal("check <i>this</i> <a href='domain.com'>link</a> out", x.xhtml_body)
    
    doc = REXML::Document.new x.to_s
    x2 = Message.new.import doc.root
    
    assert_equal(x.to_s, x2.to_s)
    assert_equal("check <i>this</i> <a href='domain.com'>link</a> out", x2.xhtml_body)
  end
  
  def test_should_raise_exception_with_invalid_xhtml_body
    x = Message.new()
    
    assert_raise Jabber::ArgumentError do 
      x.set_xhtml_body("check <i>this <a href='domain.com'>link</a> out")
    end
  end
  
  def test_subject
    x = Message.new
    assert_equal(nil, x.subject)
    subject = REXML::Element.new('subject')
    subject.text = 'A'
    x.add(subject)
    assert_equal('A', x.subject)
    x.subject = 'Test message'
    assert_equal('Test message', x.subject)
    x.each_element('subject') { |s| assert_equal('Test message', s.text) }
    assert_equal(x, x.set_subject('Breaking news'))
    assert_equal('Breaking news', x.subject)
  end

  def test_thread
    x = Message.new
    assert_equal(nil, x.thread)
    thread = REXML::Element.new('thread')
    thread.text = '123'
    x.add(thread)
    assert_equal('123', x.thread)
    x.thread = '321'
    assert_equal('321', x.thread)
    x.each_element('thread') { |s| assert_equal('321', s.text) }
    assert_equal(x, x.set_thread('abc'))
    assert_equal('abc', x.thread)
  end

  def test_chat_state
    x = Message.new
    assert_equal(nil, x.chat_state)
    chat_state = REXML::Element.new('active')
    chat_state.add_namespace('http://jabber.org/protocol/chatstates')
    x.add(chat_state)
    assert_equal(:active, x.chat_state)
    x.chat_state = :gone
    assert_equal(:gone, x.chat_state)
    assert_raise(InvalidChatState) do
      x.chat_state = :some_invalid_state
    end
    assert_equal true, x.gone?
  end

  def test_error
    x = Message.new()
    assert_equal(nil, x.error)
    e = REXML::Element.new('error')
    x.add(e)
    # test if, after an import, the error element is successfully changed
    # into an ErrorResponse object.
    x2 = Message.new.import(x)
    assert_equal(ErrorResponse, x2.first_element('error').class)
  end

  def test_answer
    orig = Message.new
    orig.from = 'a@b'
    orig.to = 'b@a'
    orig.id = '123'
    orig.type = :chat
    orig.add(REXML::Element.new('x'))

    answer = orig.answer
    assert_equal(JID.new('b@a'), answer.from)
    assert_equal(JID.new('a@b'), answer.to)
    assert_equal('123', answer.id)
    assert_equal(:chat, answer.type)
    answer.each_element { |e|
      assert_equal('x', e.name)
      assert_kind_of(X, e)
    }
  end
end
