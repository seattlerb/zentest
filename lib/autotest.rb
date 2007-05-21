require 'find'
require 'rbconfig'

$v ||= false
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
# The available hooks are: initialize, run, run_command, ran_command,
#   red, green, all_good, reset, interrupt, and quit.
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

  @@discoveries = []
  def self.add_discovery &proc
    @@discoveries << proc
  end

  def self.autodiscover
    style = []

    paths = $:.dup + Dir["vendor/plugin/*/lib"]

    begin
      require 'rubygems'
      require 'rubygems/loadpath_manager'
      Gem::LoadPathManager.build_paths
      paths.push(*Gem::LoadPathManager.paths)
    rescue LoadError
      # do nothing
    end

    hits = paths.map { |d| Dir[File.join(d, 'autotest', 'discover.rb')] }.flatten
    hits.each do |hit|
      load hit
    end

    @@discoveries.map { |proc| proc.call }.flatten.compact.sort.uniq
  end

  def self.run
    new.run
  end

  attr_accessor(:exceptions,
                :files,
                :files_to_test,
                :interrupted,
                :last_mtime,
                :libs,
                :output,
                :results,
                :tainted,
                :test_mappings,
                :unit_diff,
                :wants_to_quit)

  def initialize
    @files = Hash.new Time.at(0)
    @files_to_test = Hash.new { |h,k| h[k] = [] }
    @exceptions = false
    @libs = %w[. lib test].join(File::PATH_SEPARATOR)
    @output = $stderr
    @sleep = 1
    @unit_diff = "unit_diff -u"

    @test_mappings = {
      /^lib\/.*\.rb$/ => proc { |filename, _|
        files_matching %r%^test/.*#{File.basename(filename).gsub '_', '_?'}$%
      },
      /^test\/test_.*rb$/ => proc { |filename, _|
        filename
      }
    }

    hook :initialize
  end

  # Repeatedly run failed tests, then all tests, then
  # wait for changes and carry on until killed.
  def run
    hook :run
    reset
    add_sigint_handler

    loop do # ^c handler
      begin
        get_to_green
        if @tainted then
          rerun_all_tests
        else
          hook :all_good
        end
        wait_for_changes
      rescue Interrupt
        if @wants_to_quit then
          break
        else
          reset
        end
      end
    end
    hook :quit
  end

  # Keep running the tests after a change, until all pass.
  def get_to_green
    until all_good do
      run_tests
      wait_for_changes unless all_good
    end
  end

  # Look for files to test then run the tests and
  # handle the results.
  def run_tests
    find_files_to_test # failed + changed/affected
    cmd = make_test_cmd @files_to_test

    hook :run_command
    puts cmd

    old_sync = $stdout.sync
    $stdout.sync = true
    @results = []
    line = []
    begin
      open("| #{cmd}", "r") do |f|
        until f.eof? do
          c = f.getc
          putc c
          line << c
          if c == ?\n then
            @results << line.pack("c*")
            line.clear
          end
        end
      end
    ensure
      $stdout.sync = old_sync
    end
    hook :ran_command
    @results = @results.join

    handle_results(@results)
  end

  ############################################################
  # Utility Methods, not essential to reading of logic

  def add_sigint_handler
    trap 'INT' do
      if @interrupted then
        @wants_to_quit = true
      else
        unless hook :interrupt then
          puts "Interrupt a second time to quit"
          @interrupted = true
          sleep 1.5
        end
        raise Interrupt, nil # let the run loop catch it
      end
    end
  end

  # If there are no files left to test
  # (because they've all passed),
  # then all is good.
  def all_good
    @files_to_test.empty?
  end

  # Convert a path in a string, s, into a
  # class name, changing underscores to CamelCase,
  # etc
  def path_to_classname(s)
    sep = File::SEPARATOR
    f = s.sub(/^test#{sep}/, '').sub(/\.rb$/, '').split(sep)
    f = f.map { |path| path.split(/_/).map { |seg| seg.capitalize }.join }
    f = f.map { |path| path =~ /^Test/ ? path : "Test#{path}"  }
    f.join('::')
  end


  def consolidate_failures(failed)
    filters = Hash.new { |h,k| h[k] = [] }

    class_map = Hash[*@files.keys.grep(/^test/).map { |f| [path_to_classname(f), f] }.flatten]

    failed.each do |method, klass|
      if class_map.has_key? klass then
        filters[class_map[klass]] << method
      else
        @output.puts "Unable to map class #{klass} to a file"
      end
    end

    return filters
  end

  # Find the files to process, ignoring temporary files,
  # source configuration management files, etc., and return
  # a Hash mapping filename to modification time.
  def find_files
    result = {}
    Find.find '.' do |f|
      Find.prune if @exceptions and f =~ @exceptions and test ?d, f

      next if test ?d, f
      next if f =~ /(swp|~|rej|orig)$/        # temporary/patch files
      next if f =~ /\/\.?#/                     # Emacs autosave/cvs merge files

      filename = f.sub(/^\.\//, '')

      result[filename] = File.stat(filename).mtime rescue next
    end
    return result
  end

  # Find the files which have been modified, update
  # the recorded timestamps, and use this to update
  # the files to test. Returns true if any file is
  # newer than the previously recorded most recent
  # file.
  def find_files_to_test(files=find_files)
    updated = files.select { |filename, mtime|
      @files[filename] < mtime
    }

    p updated if $v unless updated.empty? or @last_mtime.to_i == 0

    # TODO: keep an mtime at app level and drop the files hash
    updated.each do |filename, mtime|
      @files[filename] = mtime
    end

    updated.each do |filename, mtime|
      tests_for_file(filename).each do |f|
        @files_to_test[f] # creates key with default value
      end
    end

    previous = @last_mtime
    @last_mtime = @files.values.max
    @last_mtime > previous
  end

  # Check results for failures, set the "bar" to red or
  # green, and if there are failures record this.
  def handle_results(results)
    failed = results.scan(/^\s+\d+\) (?:Failure|Error):\n(.*?)\((.*?)\)/)
    completed = results =~ /\d+ tests, \d+ assertions, \d+ failures, \d+ errors/

    @files_to_test = consolidate_failures failed if completed

    hook completed && @files_to_test.empty? ? :green : :red unless $TESTING

    @tainted = true unless @files_to_test.empty?
  end

  # Generate the commands to test the supplied files
  def make_test_cmd files_to_test
    cmds = []
    full, partial = files_to_test.partition { |k,v| v.empty? }

    unless full.empty? then
      classes = full.map {|k,v| k}.flatten.uniq.sort.join(' ')
      cmds << "#{ruby} -I#{@libs} -rtest/unit -e \"%w[#{classes}].each { |f| require f }\" | #{unit_diff}"
    end

    partial.each do |klass, methods|
      cmds << "#{ruby} -I#{@libs} #{klass} -n \"/^(#{Regexp.union(*methods).source})$/\" | #{unit_diff}"
    end

    return cmds.join('; ')
  end

  # Rerun the tests from cold (reset state)
  def rerun_all_tests
    reset
    run_tests
    hook :all_good if all_good
  end

  # Clear all state information about test failures
  # and whether interrupts will kill autotest.
  def reset
    @interrupted = @wants_to_quit = false
    @files.clear
    @files_to_test.clear
    @last_mtime = Time.at(0)
    find_files_to_test # failed + changed/affected
    @tainted = false
    hook :reset
  end

  # determine and return the path of the ruby executable.
  def ruby
    ruby = File.join(Config::CONFIG['bindir'],
                     Config::CONFIG['ruby_install_name'])

    unless File::ALT_SEPARATOR.nil? then
      ruby.gsub! File::SEPARATOR, File::ALT_SEPARATOR
    end

    return ruby
  end


  # Return the name of the file with the tests for
  # filename.
  def tests_for_file(filename)
    result = @test_mappings.find { |file_re, ignored| filename =~ file_re }
    result = result.nil? ? [] : Array(result.last.call(filename, $~))

    @output.puts "Dunno! #{filename}" if $TESTING and result.empty?

    result.sort.uniq
  end

  # Sleep then look for files to test, until there
  # are some.
  def wait_for_changes
    hook :waiting
    begin
      sleep @sleep
    end until find_files_to_test
  end

  def files_matching regexp
    @files.keys.select { |k|
      k =~ regexp
    }
  end

  ############################################################
  # Hooks:

  def hook(name)
    HOOKS[name].inject(false) do |handled,plugin|
      plugin[self] || handled
    end
  end

  # Add the supplied block to the available hooks, with
  # the given name.
  def self.add_hook(name, &block)
    HOOKS[name] << block
  end
end

if test ?f, './.autotest' then
  load './.autotest'
elsif test ?f, File.expand_path('~/.autotest') then
  load File.expand_path('~/.autotest')
end
