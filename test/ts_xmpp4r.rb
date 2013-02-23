#!/usr/bin/ruby -w

$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
$:.unshift File.join(File.dirname(__FILE__), '..', 'test')
$:.unshift File.join(File.dirname(__FILE__), 'lib')
$:.unshift File.join(File.dirname(__FILE__), 'test')

# This is allowed here, to make sure it's enabled in all test.
Thread::abort_on_exception = true

require 'xmpp4r'
require 'find'

# List files' basenames, not full path!
# EXCLUDED_FILES = [ 'tc_muc_simplemucclient.rb' ]
EXCLUDED_FILES = %w[
  tc_disconnect_cleanup.rb
  ./pubsub/tc_helper.rb
  ./muc/tc_muc_mucclient.rb
  ./reliable/tc_reliable_connection.rb
  ./reliable/tc_disconnect_exception.rb
  ./reliable/tc_listener_mocked_test.rb
  ./reliable/tc_reliable_connection.rb
  ./bytestreams/tc_socks5bytestreams.rb
].map {|f| f.gsub(%r[^\.], File.dirname(__FILE__)) }

tc_files = []
tc_subdirs = []
Find.find(File.dirname(__FILE__)) do |f|
  if File::directory?(f)
    if f == '.'
      # do nothing
    elsif File::basename(f) != '.svn'
      tc_subdirs << f
      Find.prune
    end
  elsif File::basename(f) =~ /^tc.*\.rb$/
    tc_files << f
  end
end

tc_subdirs.each do |dir|
  Find.find(dir) do |f|
    if File::file?(f) and File::basename(f) =~ /^tc.*\.rb$/
      tc_files << f
    end
  end
end

tc_files.each do |f|
  next if EXCLUDED_FILES.include?(File::basename(f)) or EXCLUDED_FILES.include?(f)
  require f
end
