# -*- ruby -*-

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rbconfig'

$: << 'lib'
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
task :update_manifest => :clean do
  sh "p4 open Manifest.txt; find . -type f | sed -e 's%./%%' | sort > Manifest.txt"
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

$prefix = ENV['PREFIX'] || Config::CONFIG['prefix']
$bin  = File.join($prefix, 'bin')
$lib  = Config::CONFIG['sitelibdir']
$bins = %w(ZenTest autotest unit_diff)
$libs = %w(ZenTest.rb autotest.rb rails_autotest.rb unit_diff.rb)

task :install do
  $bins.each do |f|
    install File.join("bin", f), $bin, :mode => 0555
  end

  $libs.each do |f|
    install File.join("lib", f), $lib, :mode => 0444
  end
end

task :uninstall do
  $bins.each do |f|
    rm_f File.join($bin, f)
  end

  $libs.each do |f|
    rm_f File.join($lib, f)
  end
end

desc 'Clean up'
task :clean => [ :clobber_rdoc, :clobber_package ] do
  rm_rf %w(*~ doc)
end
