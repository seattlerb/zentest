require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'

require 'ZenTest'

$VERBOSE = nil

spec = Gem::Specification.new do |s|
  s.name = 'ZenTest'
  s.version = ZenTest::VERSION
  s.summary = ''
  s.authors = ['Ryan Davis', 'Eric Hodel']
  s.email = 'ryand-ruby@zenspider.com'

  s.files = File.read('Manifest.txt').split($/)
  s.require_path = 'lib'
  s.executables = %w[ZenTest unit_diff autotest]
end

desc 'Run tests'
task :default => :test

desc 'Run tests'
Rake::TestTask.new :test do |t|
  t.libs << 'test'
  t.verbose = true
end

desc 'Update Manifest.txt'
task :update_manifest do
  sh "p4 open Manifest.txt; find . -type f | sed -e 's%./%%' | egrep -v 'swp|~' | egrep -v '^(doc|pkg)/' | sort > Manifest.txt"
end

desc 'Generate RDoc'
Rake::RDocTask.new :rdoc do |rd|
  rd.rdoc_dir = 'doc'
  rd.rdoc_files.add 'lib', 'README.txt', 'History.txt',
                    'LinuxJournalArticle.txt'
  rd.main = 'README.txt'
  rd.options << '-d' if `which dot` =~ /\/dot/
end

desc 'Build Gem'
Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = true
end

desc 'Clean up'
task :clean => [ :clobber_rdoc, :clobber_package ]

