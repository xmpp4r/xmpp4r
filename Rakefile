require 'rake'
require 'rake/gempackagetask'
require 'rake/testtask'
require 'rake/rdoctask'
require 'find'

begin
  require 'rubygems'
  require 'rcov/rcovtask'
  RCOV = true
rescue LoadError
  RCOV = false
end

task :default => [:test]

# read the contents of the gemspec, eval it, and assign it to 'spec'
# this lets us maintain all gemspec info in one place.  Nice and DRY.
spec = eval(IO.read("xmpp4r.gemspec"))

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.gem_spec = spec
  pkg.need_zip = true
  pkg.need_tar = true
end

task :install_gem => [:package] do
  sh %{sudo gem install pkg/#{GEM}-#{VER}}
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
