#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/iqquery'
include Jabber

class IqQueryTest < Test::Unit::TestCase
  def test_create
    x = IqQuery::new()
    assert_equal("query", x.name)
    assert_equal("<query/>", x.to_s)
  end

  def test_import
    q = IqQuery::new
    assert_equal(IqQuery, q.class)

    e = XMLElement.new('query')
    e.add_namespace('jabber:iq:roster')
    # kind_of? only checks that the class belongs to the IqQuery class
    # hierarchy.
    assert(IqQuery.import(e).kind_of?(IqQuery))

    # Importing specific derivates is to be tested in the test case of the derivate
    # (e.g. tc_iqqueryroster.rb)
  end
end