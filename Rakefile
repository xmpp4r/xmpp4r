#!/usr/bin/ruby -w

require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rake/rdoctask'
require 'find'

begin
  require 'rcov/rcovtask'
  RCOV = true
rescue LoadError
  RCOV = false
end

PKG_NAME = 'xmpp4r'
PKG_VERSION = '0.3.2'

PKG_FILES = ['ChangeLog', 'README.rdoc', 'COPYING', 'LICENSE', 'setup.rb', 'Rakefile', 'README_ruby19.txt', 'xmpp4r.gemspec' ]
Find.find('lib/', 'data/', 'test/', 'tools/') do |f|
  if FileTest.directory?(f) and f =~ /\.svn/
    Find.prune
  else
    PKG_FILES << f
  end
end

Rake::PackageTask.new(PKG_NAME, PKG_VERSION) do |p|
  p.need_tar = true
  p.package_files = PKG_FILES
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = ['test/ts_xmpp4r.rb']
end

Rake::RDocTask.new do |rd|
  f = []
  require 'find'
  Find.find('lib/') do |file|
    # Skip hidden files (.svn/ directories and Vim swapfiles)
    if file.split(/\//).last =~ /^\./
      Find.prune
    else
      f << file if not FileTest.directory?(file)
    end
  end
  f.delete('lib/xmpp4r.rb')
  # hack to document the Jabber module properly
  f.unshift('lib/xmpp4r.rb')
  rd.rdoc_files.include(f)
  rd.options << '--all'
  rd.options << '--fileboxes'
  rd.options << '--diagram'
  rd.options << '--inline-source'
  rd.options << '--line-numbers'
  rd.rdoc_dir = 'rdoc'
end

if RCOV
  Rcov::RcovTask.new do |t|
    t.test_files = ['test/ts_xmpp4r.rb']
  end
end

desc "Generate Requires Graph"
task :gen_requires_graph do
  sh %{cd tools; ./gen_requires.bash}
end

begin
  require 'rubygems'
  require 'rake/gempackagetask'

  # read the contents of the gemspec, eval it, and assign it to 'spec'
  # this lets us maintain all gemspec info in one place.  Nice and DRY.
  spec = eval(IO.read("xmpp4r.gemspec"))

  Rake::GemPackageTask.new(spec) do |pkg|
    pkg.gem_spec = spec
    pkg.need_zip = true
    pkg.need_tar = true
  end

  desc "Build and install Gem locally"
  task :install_gem => [:package] do
    sh %{sudo gem install pkg/#{GEM}-#{VER}}
  end

rescue LoadError
  puts "Will not generate Rubygem"
end
