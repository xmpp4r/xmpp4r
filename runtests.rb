#!/usr/bin/ruby

$:.unshift 'lib'

Dir.glob('test/*.rb') { |filename|
  require filename
}
