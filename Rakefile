# -*- ruby -*-

$: << 'lib'

require 'rubygems'
require 'hoe'
require './lib/zentest.rb'

Hoe.new("ZenTest", ZenTest::VERSION) do |zentest|
  zentest.developer('Ryan Davis', 'ryand-ruby@zenspider.com')
  zentest.developer('Eric Hodel', 'drbrain@segment7.net')
end

task :autotest do
  ruby "-Ilib -w ./bin/autotest"
end

task :update do
  File.open "example_dot_autotest.rb", "w" do |f|
    f.puts "# -*- ruby -*-"
    f.puts
    Dir.chdir "lib" do
      Dir["autotest/*.rb"].sort.each do |s|
        f.puts "# require '#{s[0..-4]}'"
      end
    end

    f.puts
    f.puts "# Autotest::AutoUpdate.sleep_time = 60"
    f.puts "# Autotest::AutoUpdate.update_cmd = 'svn up'"
    f.puts "# Autotest::Emacs.client_cmd = 'emacsclient -e'"
    f.puts "# Autotest::Heckle.flags << '-t test/**/*.rb'"
    f.puts "# Autotest::Heckle.klasses << 'MyClass'"
    f.puts "# Autotest::Shame.chat_app = :adium"
  end
end

task :sort do
  begin
    sh 'for f in lib/*.rb; do echo $f; grep "^ *def " $f | grep -v sort=skip > x; sort x > y; echo $f; echo; diff x y; done'
    sh 'for f in test/test_*.rb; do echo $f; grep "^ *def.test_" $f > x; sort x > y; echo $f; echo; diff x y; done'
  ensure
    sh 'rm x y'
  end
end

task :rcov_info do
  ruby "-Ilib -S rcov --text-report --save coverage.info test/test_*.rb"
end

task :rcov_overlay do
  rcov, eol = Marshal.load(File.read("coverage.info")).last[ENV["FILE"]], 1
  puts rcov[:lines].zip(rcov[:coverage]).map { |line, coverage|
    bol, eol = eol, eol + line.length
    [bol, eol, "#ffcccc"] unless coverage
  }.compact.inspect
end

# vim:syntax=ruby

