#!/usr/local/bin/ruby -w -I.

VERSION = '1.0.0'

puts "# Created with ZenTest v. #{VERSION}"

$AUTOTESTER = true

module Kernel
  alias :old_at_exit :at_exit
  def at_exit()
    # nothing to do...
  end
end

require 'test/unit'
require 'test/unit/ui/console/testrunner'

files = ARGV.clone

test_klasses = {}
klasses = {}
all_methods = {} # fallback

ARGV.each do |file|

  begin
    require "#{file}"
  rescue LoadError => err
    puts "Couldn't load #{file}: #{err}"
    next
  end

  IO.foreach(file) do |line|
    if line =~ /^\s*class\s+(\S+)/ then
      klassname = $1
      klass = Module.const_get(klassname.intern)
      target = klassname =~ /^Test/ ? test_klasses : klasses

      # record public instance methods JUST in this class
      public_methods = klass.public_instance_methods
      klassmethods = {}
      public_methods.each do |meth|
	klassmethods[meth] = true
      end
      target[klassname] = klassmethods
      
      # record ALL instance methods including superclasses (minus Object)
      the_methods = klass.instance_methods(true) - Object.instance_methods(true)
      klassmethods = {}
      the_methods.each do |meth|
	klassmethods[meth] = true
      end
      all_methods[klassname] = klassmethods
    end
  end
end

print "# "
p all_methods

missing_methods = {} # key = klassname, val = array of methods

klasses.each_key do |klassname|
  testklassname = "Test#{klassname}"

  if test_klasses[testklassname] then
    methods = klasses[klassname]
    testmethods = test_klasses[testklassname]

    # check that each method has a test method
    klasses[klassname].each_key do | methodname |
      testmethodname = "test_#{methodname}".gsub(/\[\]=/, "index_equals").gsub(/\[\]/, "index_accessor")
      unless testmethods[testmethodname] then
	puts "# ERROR method #{testklassname}\##{testmethodname} does not exist (1)" if $VERBOSE
	missing_methods[testklassname] ||= []
	missing_methods[testklassname].push(testmethodname)
      end
    end
    # check that each test method has a method
    testmethods.each_key do | testmethodname |
      if testmethodname =~ /^test_(.*)/ then
	methodname = $1.gsub(/index_equals/, "[]=").gsub(/index_accessor/, "[]")

	# try the current name
	orig_name = methodname.dup
	found = false
	until methodname == "" or methods[methodname] or all_methods[klassname][methodname] do
	  # try the name minus an option (ie mut_opt1 -> mut)
	  if methodname.sub!(/_[^_]+$/, '') then
	    if methods[methodname] or all_methods[klassname][methodname] then
	      found = true
	    end
	  else
	    break # no more substitutions will take place
	  end
	end

	unless found or methods[methodname] or methodname == "initialize" then
	  puts "# ERROR method #{klassname}\##{orig_name} does not exist (2)" if $VERBOSE
	  missing_methods[klassname] ||= []
	  missing_methods[klassname].push(orig_name)
	end

      else
	unless testmethodname =~ /^util_/ then
	  puts "# WARNING Skipping #{testklassname}\##{testmethodname}"
	end
      end
    end
  else
    puts "# ERROR test class #{testklassname} does not exist" if $VERBOSE

    missing_methods[testklassname] ||= []
    klasses[klassname].keys.each do |meth|
      missing_methods[testklassname].push("test_#{meth}")
    end
  end
end

missing_methods.keys.sort.each do |klass|
  testklass = klass =~ /^Test/

  puts "class #{klass}" + (testklass ? " < Test::Unit::TestCase" : '')

  methods = missing_methods[klass] | []
  m = []
  methods.sort.each do |method|

    if testklass then
      s = "  def #{method}\n    assert(false, 'Need to write #{method} tests')\n  end"
    else
      s = "  def #{method}\n    # TO" + "DO: write some code\n  end"
    end
    m.push(s)
  end

  puts m.join("\n\n")

  puts "end"
  puts ""
end

