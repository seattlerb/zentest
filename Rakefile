# -*- ruby -*-

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
require 'rake/contrib/sshpublisher'
require 'rbconfig'

require './lib/zentest.rb'

$VERBOSE = nil

spec = Gem::Specification.new do |s|
  s.name = 'ZenTest'
  s.version = ZenTest::VERSION
  s.authors = ['Ryan Davis', 'Eric Hodel']
  s.email = 'ryand-ruby@zenspider.com'

  s.files = IO.readlines("Manifest.txt").map {|f| f.chomp }
  s.require_path = 'lib'

  s.executables = s.files.grep(/^bin\//).map { |f| File.basename f }

  paragraphs = File.read("README.txt").split(/\n\n+/)
  s.instance_variable_set "@description", paragraphs[3..10].join("\n\n")
  s.instance_variable_set "@summary", paragraphs[12]

  s.homepage = "http://www.zenspider.com/ZSS/Products/ZenTest/"
  s.rubyforge_project = "zentest"
  s.has_rdoc = true

  if $DEBUG then
    puts "#{s.name} #{s.version}"
    puts
    puts s.executables.sort.inspect
    puts
    puts "** summary:"
    puts s.summary
    puts
    puts "** description:"
    puts s.description
  end
end

desc 'Build Gem'
Rake::GemPackageTask.new spec do |pkg|
  pkg.need_tar = true
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
  rd.rdoc_files.add 'lib', 'README.txt', 'History.txt', 'LinuxJournalArticle.txt'
  rd.main = 'README.txt'
  rd.options << '-d' if `which dot` =~ /\/dot/ unless RUBY_PLATFORM =~ /win32/
  rd.options << '-t ZenTest RDoc'
end
  
desc 'Upload RDoc to RubyForge'
task :upload => :rdoc do
    
  user = "#{ENV['USER']}@rubyforge.org"
  project = '/var/www/gforge-projects/zentest'
  local_dir = 'doc'
  pub = Rake::SshDirPublisher.new user, project, local_dir
  pub.upload
end

$prefix = ENV['PREFIX'] || Config::CONFIG['prefix']
$bin  = File.join($prefix, 'bin')
$lib  = Config::CONFIG['sitelibdir']
$bins = spec.executables
$libs = spec.files.grep(/^lib\//).map { |f| f.sub(/^lib\//, '') }.sort

task :blah do
    p $bins
    p $libs
end

task :install do
  $bins.each do |f|
    install File.join("bin", f), $bin, :mode => 0555
  end

  $libs.each do |f|
    dir = File.join($lib, File.dirname(f))
    mkdir_p dir unless test ?d, dir
    install File.join("lib", f), dir, :mode => 0444
  end
end

task :uninstall do
  # add old versions
  $bins << "ZenTest"
  $libs << "ZenTest.rb"  

  $bins.each do |f|
    rm_f File.join($bin, f)
  end

  $libs.each do |f|
    rm_f File.join($lib, f)
  end

  rm_rf File.join($lib, "test")
end

desc 'Clean up'
task :clean => [ :clobber_rdoc, :clobber_package ] do
  rm_f Dir["**/*~"]
end

task :help do
  Rake.application.options.show_task_pattern = //
  Rake.application.display_tasks_and_comments
end

# vim:syntax=ruby

