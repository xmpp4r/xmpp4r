#!/usr/bin/ruby

$:.unshift '../lib'

require 'test/unit'
require 'xmpp4r/idgenerator'
include Jabber

class IdGeneratorTest < Test::Unit::TestCase
  def test_instances
    assert_equal(Jabber::IdGenerator.instance, Jabber::IdGenerator.instance)
  end

  def test_unique
    ids = []
    100.times { ids.push(Jabber::IdGenerator.generate_id) }

    ids.each_index { |a|
      ids.each_index { |b|
        if a == b
          assert_equal(ids[a], ids[b])
        else
          assert_not_equal(ids[a], ids[b])
        end
      }
    }
  end
end
