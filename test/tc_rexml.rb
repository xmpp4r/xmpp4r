#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'

class REXMLTest < Test::Unit::TestCase
  def test_simple
    e = REXML::Element.new('e')
    assert_kind_of(REXML::Element, e)
    assert_nil(e.text)
    assert_nil(e.attributes['x'])
  end

  def test_text_entities
    e = REXML::Element.new('e')
    e.text = '&'
    assert_equal('<e>&amp;</e>', e.to_s)
    e.text = '&amp;'
    assert_equal('<e>&amp;amp;</e>', e.to_s)
    e.text = '&nbsp'
    assert_equal('<e>&amp;nbsp</e>', e.to_s)
    e.text = '&nbsp;'
    assert_equal('<e>&amp;nbsp;</e>', e.to_s)
  end

  def test_attribute_entites
    e = REXML::Element.new('e')
    e.attributes['x'] = '&'
    assert_equal('&', e.attributes['x'])
    e.attributes['x'] = '&amp;'
    assert_equal('&amp;', e.attributes['x'])
    e.attributes['x'] = '&nbsp'
    assert_equal('&nbsp', e.attributes['x'])
    e.attributes['x'] = '&nbsp;'
    assert_equal('&nbsp;', e.attributes['x'])
    p e.to_s
  end
end
