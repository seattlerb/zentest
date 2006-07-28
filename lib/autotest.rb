require 'find'
require 'rbconfig'

$TESTING = false unless defined? $TESTING

##
# Autotest continuously scans the files in your project for changes
# and runs the appropriate tests.  Test failures are run until they
# have all passed. Then the full test suite is run to ensure that
# nothing else was inadvertantly broken.
#
# If you want Autotest to start over from the top, hit ^C once.  If
# you want Autotest to quit, hit ^C twice.
#
# Rails:
#
# The autotest command will automatically discover a Rails directory
# by looking for config/environment.rb. When Rails is discovered,
# autotest uses RailsAutotest to perform file mappings and other work.
# See RailsAutotest for details.
#
# Plugins:
#
# Plugins are available by creating a .autotest file either in your
# project root or in your home directory. You can then write event
# handlers in the form of:
#
#   Autotest.add_hook hook_name { |autotest| ... }
#
# The available hooks are: run, interrupt, quit, ran_command, red,
#   green, all_good, and reset.
#
# See example_dot_autotest.rb for more details.
#
# Naming:
#
# Autotest uses a simple naming scheme to figure out how to map
# implementation files to test files following the Test::Unit naming
# scheme.
#
# * Test files must be stored in test/
# * Test files names must start with test_
# * Test class names must start with Test
# * Implementation files must be stored in lib/
# * Implementation files must match up with a test file named
#   test_.*implementation.rb
#
# Strategy:
#
# 1) find all files and associate them from impl <-> test
# 2) run all tests
# 3) scan for failures
# 4) detect changes in ANY (ruby?) file, rerun all failures + changed files
# 5) until 0 defects, goto 3
# 6) when 0 defects, goto 2

class Autotest

  HOOKS = Hash.new { |h,k| h[k] = [] }

  def self.run
    new.run
  end

  attr_accessor :exceptions, :files, :files_to_test, :interrupted, :last_mtime, :libs, :output, :tainted

  def initialize
    @files = Hash.new Time.at(0)
    @files_to_test = Hash.new { |h,k| h[k] = [] }
    @exceptions = false
    @libs = '.:lib:test'
    @output = $stderr
    @sleep = 2
  end

  def run
    hook :run
    reset
    add_sigint_handler

    loop do # ^c handler
      begin
        get_to_green
        rerun_all_tests if @tainted
        wait_for_changes
      rescue Interrupt
        if @wants_to_quit then
          break
        else
          reset
          hook :interrupt
        end
      end
    end
    hook :quit
  end

  def get_to_green
    until all_good do
      run_tests
      wait_for_changes unless all_good
    end
  end

  def run_tests
    find_files_to_test # failed + changed/affected
    cmd = make_test_cmd @files_to_test

    puts cmd

    @results = `#{cmd}`
    hook :ran_command
    puts @results

    handle_results(@results)
  end

  ############################################################
  # Utility Methods, not essential to reading of logic

  def add_sigint_handler
    trap 'INT' do
      if @interrupted then
        @wants_to_quit = true
      else
        puts "Interrupt a second time to quit"
        @interrupted = true
        sleep 1.5
        raise Interrupt                 # let the run loop catch it
      end
    end
  end

  def all_good
    @files_to_test.empty?
  end

  def consolidate_failures(failed)
    filters = Hash.new { |h,k| h[k] = [] }

    failed.each do |method, klass|
      failed_file_name = klass.gsub(/(.)([A-Z])/, '\1_?\2')
      failed_files = @files.keys.grep(/#{failed_file_name}/i)
      case failed_files.size
      when 0 then
        @output.puts "Unable to map class #{klass} to a file" # FIX for testing
      when 1 then
        filters[failed_files.last] << method
      else
        @output.puts "multiple files matched class #{klass} #{failed_files.inspect}."
        # nothing yet
      end
    end

    return filters
  end

  def find_files
    result = {}
    Find.find '.' do |f|
      Find.prune if @exceptions and f =~ @exceptions and test ?d, f
      Find.prune if f =~ /(\.(svn|hg)|CVS|tmp|public|doc|pkg)$/ # prune dirs

      next if test ?d, f
      next if f =~ /(swp|~|rej|orig)$/        # temporary/patch files
      next if f =~ /\/\.?#/                     # Emacs autosave/cvs merge files

      filename = f.sub(/^\.\//, '')

      result[filename] = File.stat(filename).mtime
    end
    return result
  end

  def find_files_to_test(files=find_files)
    updated = []

    # TODO: keep an mtime at app level and drop the files hash
    files.each do |filename, mtime|
      next if @files[filename] >= mtime

      tests_for_file(filename).each do |f|
        @files_to_test[f] # creates key with default value
      end

      @files[filename] = mtime
    end

    previous = @last_mtime
    @last_mtime = @files.values.sort.last
    @last_mtime > previous
  end

  def handle_results(results)
    failed = results.scan(/^\s+\d+\) (?:Failure|Error):\n(.*?)\((.*?)\)/)
    @files_to_test = consolidate_failures failed
    unless @files_to_test.empty? then
      hook :red
    else
      hook :green
    end unless $TESTING
    @tainted = true unless @files_to_test.empty?
  end

  def make_test_cmd files_to_test
    cmds = []
    full, partial = files_to_test.partition { |k,v| v.empty? }

    unless full.empty? then
      classes = full.map {|k,v| k}.flatten.join(' ')
      cmds << "#{ruby} -I#{@libs} -rtest/unit -e \"%w[#{classes}].each { |f| load f }\" | unit_diff -u"
    end

    partial.each do |klass, methods|
      cmds << "#{ruby} -I#{@libs} #{klass} -n \"/^(#{Regexp.union(*methods).source})$/\" | unit_diff -u" 
    end

    return cmds.join('; ')
  end

  def rerun_all_tests
    reset
    run_tests
    hook :all_good if all_good
  end

  def reset
    @interrupted = @wants_to_quit = false
    @files.clear
    @files_to_test.clear
    @last_mtime = Time.at(0)
    find_files_to_test # failed + changed/affected
    @tainted = false
    hook :reset
  end
  
  def ruby
    ruby = File.join(Config::CONFIG['bindir'],
                     Config::CONFIG['ruby_install_name'])

    unless File::ALT_SEPARATOR.nil? then
      ruby.gsub! File::SEPARATOR, File::ALT_SEPARATOR
    end

    return ruby
  end

  def tests_for_file(filename)
    case filename
    when /^lib\/.*\.rb$/ then
      impl = File.basename(filename).gsub '_', '_?'
      @files.keys.select do |k|
        k =~ %r%^test/.*#{impl}$%
      end
    when /^test\/test_.*rb$/ then
      [filename]
    else
      @output.puts "Dunno! #{filename}" if $TESTING
      []
    end
  end

  def wait_for_changes
    begin
      sleep @sleep
    end until find_files_to_test
  end

  ############################################################
  # Hooks:

  def hook(name)
    HOOKS[name].each do |plugin|
      plugin[self]
    end
  end

  def self.add_hook(name, &block)
    HOOKS[name] << block
  end
end

if test ?f, './.autotest' then
  load './.autotest'
elsif test ?f, File.expand_path('~/.autotest') then
  load File.expand_path('~/.autotest')
else
  puts "couldn't find ./.autotest in #{Dir.pwd}"
end
