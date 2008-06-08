#!/usr/bin/ruby

$:.unshift File::dirname(__FILE__) + '/../lib'

require 'test/unit'
require 'xmpp4r/rexmladdons'

class REXMLTest < Test::Unit::TestCase
  def test_simple
    e = REXML::Element.new('e')
    assert_kind_of(REXML::Element, e)
    assert_nil(e.text)
    assert_nil(e.attributes['x'])
  end

  def test_normalize
    assert_equal('&amp;', REXML::Text::normalize('&'))
    assert_equal('&amp;amp;', REXML::Text::normalize('&amp;'))
    assert_equal('&amp;amp;amp;', REXML::Text::normalize('&amp;amp;'))
    assert_equal('&amp;nbsp;', REXML::Text::normalize('&nbsp;'))
  end

  def test_unnormalize
    assert_equal('&', REXML::Text::unnormalize('&amp;'))
    assert_equal('&amp;', REXML::Text::unnormalize('&amp;amp;'))
    assert_equal('&amp;amp;', REXML::Text::unnormalize('&amp;amp;amp;'))
    assert_equal('&nbsp;', REXML::Text::unnormalize('&amp;nbsp;'))
    assert_equal('&nbsp;', REXML::Text::unnormalize('&nbsp;'))  # ?
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
    e.text = '&<;'
    assert_equal('<e>&amp;&lt;;</e>', e.to_s)
    e.text = '<>"\''
    assert_equal('<e>&lt;&gt;&quot;&apos;</e>', e.to_s)
    e.text = '<x>&amp;</x>'
    assert_equal('<e>&lt;x&gt;&amp;amp;&lt;/x&gt;</e>', e.to_s)
  end

  def test_attribute_entites
    e = REXML::Element.new('e')
    e.attributes['x'] = '&'
    assert_equal('&', e.attributes['x'])
    e.attributes['x'] = '&amp;'
    # bug in REXML 3.1.6 unescaped the ampersand
    # assert_equal('&', e.attributes['x'])
    # substituting a test that works with 3.1.5, 3.1.6, and 3.1.7
    assert_equal('&amp;amp;', e.attribute('x').to_s)
    e.attributes['x'] = '&nbsp'
    assert_equal('&nbsp', e.attributes['x'])
    e.attributes['x'] = '&nbsp;'
    assert_equal('&nbsp;', e.attributes['x'])
  end

  # test '==(o)'

  def test_passing_in_non_rexml_element_as_self
    o = Object.new
    assert_not_equal(o, REXML::Element.new('foo'))
  end

  def test_passing_in_non_rexml_element_as_comparison_object
    o = Object.new
    assert_not_equal(REXML::Element.new('foo'), o)
  end

  def test_element_equal_simple
    assert_equal(REXML::Element.new('foo'), REXML::Element.new('foo'))
  end

  def test_element_not_equal_simple
    assert_not_equal(REXML::Element.new('foo'), REXML::Element.new('bar'))
  end

  def test_element_equal_when_all_are_same
    e1 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e1.attributes['a:bar'] = 'baz'
    e2 = REXML::Element.new('foo')
    e2.add_namespace('a', 'urn:test:foo')
    e2.attributes['a:bar'] = 'baz'

    assert_equal(e1, e2)
  end

  def test_element_not_equal_when_namespace_name_differs
    e1 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e1.attributes['a:bar'] = 'baz'
    e2 = REXML::Element.new('foo')
    e2.add_namespace('b', 'urn:test:foo')
    e2.attributes['a:bar'] = 'baz'

    assert_not_equal(e1, e2)
  end

  def test_element_not_equal_when_namespace_value_differs
    e1 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e1.attributes['a:bar'] = 'baz'
    e2 = REXML::Element.new('foo')
    e2.add_namespace('a', 'urn:test:bar')
    e2.attributes['a:bar'] = 'baz'

    assert_not_equal(e1, e2)
  end

  def test_element_not_equal_when_attribute_name_differs
    e1 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e1.attributes['a:bar'] = 'baz'
    e2 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e2.attributes['b:bar'] = 'baz'

    assert_not_equal(e1, e2)
  end

  def test_element_not_equal_when_attribute_value_differs
    e1 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e1.attributes['a:bar'] = 'baz'
    e2 = REXML::Element.new('foo')
    e1.add_namespace('a', 'urn:test:foo')
    e2.attributes['a:bar'] = 'bar'

    assert_not_equal(e1, e2)
  end

end
