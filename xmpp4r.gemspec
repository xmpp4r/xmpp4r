# This was slapped together by
# Nolan Eakins <sneakin @t  semanticgap.com>
# for the XMPP4R library.

require 'rubygems'
require 'rake'

def Gem.complete_file_list(dir)
  ret = Array.new

  list = Dir.new(dir).entries
  list.delete_if { |d| d =~ /^\.+/ }
  list.map! { |f| "#{dir}/#{f}" }

  list.each do |file|
    if File.file?(file)
      ret.push file
    else
      sub = complete_file_list(file)
      ret.concat(sub)
    end
  end

  return ret
end

spec = Gem::Specification.new do |s|
  s.name = 'xmpp4r'
  s.version = '0.0.1'
  s.authors = ['Lucas Nussbaum', 'Stephan Maka']
  s.email = 'xmpp4r-devel@gna.org'
  s.homepage = 'http://home.gna.org/xmpp4r/'
  s.platform = Gem::Platform::RUBY
  s.summary = 'XMPP4R is an XMPP/Jabber library for Ruby.'
  s.files = ['README', 'COPYING', 'ChangeLog'].concat(Gem::complete_file_list('lib')).concat(Gem::complete_file_list('data'))

  s.has_rdoc = true
  s.autorequire = 'xmpp4r'
end

if $0 == __FILE__
  Gem::manage_gems
  Gem::Builder.new(spec)
end
