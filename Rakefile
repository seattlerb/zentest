# -*- ruby -*-

ENV["RUBY_FLAGS"]="-Ilib:bin:test" # FIX

require 'rubygems'
require 'hoe'
require './lib/zentest.rb'

Hoe.new("ZenTest", ZenTest::VERSION) do |p|
  paragraphs = File.read("README.txt").split(/\n\n+/)

  p.author = ['Ryan Davis', 'Eric Hodel']

  changes = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  summary, *description = p.paragraphs_of("README.txt", 3, 3..8)

  p.changes = changes
  p.summary = summary
  p.description = description.join("\n\n")
end

task :autotest do
  ruby "-Ilib ./bin/autotest"
end

task :sort do
  begin
    sh 'for f in lib/*.rb; do echo $f; grep "^ *def " $f | grep -v sort=skip > x; sort x > y; echo $f; echo; diff x y; done'
    sh 'for f in test/test_*.rb; do echo $f; grep "^ *def.test_" $f > x; sort x > y; echo $f; echo; diff x y; done'
  ensure
    sh 'rm x y'
  end
end

# vim:syntax=ruby

