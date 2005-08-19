require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'

Rake::TestTask.new do |t|
	t.libs << "test"
	t.test_files = FileList['test/tc_*.rb']
end

Rake::RDocTask.new do |rd|
	rd.main = 'README'
	rd.rdoc_files.include('lib/*.rb', 'lib/xmpp4r/*.rb')
	rd.options << '--all'
	rd.options << '--diagram'
	rd.options << '--fileboxes'
	rd.options << '--inline-source'
	rd.options << '--line-numbers'
	rd.rdoc_dir = 'rdoc'
end

Rake::PackageTask.new('xmpp4r', '0.1') do |p|
	p.need_tar = true
	p.package_files.include('ChangeLog', 'README', 'COPYING', 'setup.rb', 'Rakefile', 'examples/*', 'examples/*/*', 'test/*.rb', 'lib/*.rb', 'lib/xmpp4r/*.rb')
end

