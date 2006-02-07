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
  s.executables = %w[zentest unit_diff autotest]
end

desc 'Run tests'
task :default => :test

desc 'Run tests'
task :test => [ :test_new, :test_old ]

desc 'The new tests' # TODO make me just test
Rake::TestTask.new :test_new do |t|
  t.libs << 'test'
  t.verbose = true
end

desc 'The old tests' # TODO remove me
task :test_old do
  sh "ruby -I. ./TestZenTest.rb #{ENV['TEST']}"
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
Rake::GemPackageTask.new spec do end # WTF? A block is required?

desc 'Clean up'
task :clean => [ :clobber_rdoc, :clobber_package ]

