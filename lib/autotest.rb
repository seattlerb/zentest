$TESTING = defined? $TESTING

require 'find'
require 'rbconfig'

##
# Autotest continuously runs your tests as you work on your project.
#
# Autotest periodically scans the files in your project for updates then
# figures out the appropriate tests to run and runs them.  If a test fails
# Autotest will run just that test until you get it to pass.
#
# If you want Autotest to start over from the top, hit ^C.  If you want
# Autotest to quit, hit ^C twice.
#
# The autotest command will automatically discover a Rails directory by
# looking for config/environment.rb.  If you don't have one you can force
# rails mode by passing -rails to autotest.
#
# When Rails is discovered autotest uses RailsAutotest to perform file
# mappings and other work.  See RailsAutotest for details.
#
# Autotest uses a simple naming scheme to figure out how to map implementation
# files to test files following the Test::Unit naming scheme.
#
# * Test files must be stored in test/
# * Test files names must start with test_
# * Test classes must start with Test
# * Implementation files must be stored in lib/
# * Implementation files must match up with a test file named
#   test_.*implementation.rb
#--
# New (proposed) strategy:
#
# 1) find all files and associate them from impl <-> test
# 2) run all tests
# 3) scan for failures
# 4) detect changes in ANY (ruby?) file, rerun all failures + changed files
#    NOTE: this runs in a loop, loop handling should be improved slightly to
#          have less crap (ruby command, failure count).
# 5) until 0 defects, goto 3
# 6) when 0 defects, goto 2

class Autotest
  
  def self.run
    new.run
  end

  ##
  # Creates a new Autotest.  If @exceptions is set, updated_files will use it
  # to reject filenames.

  def initialize
    @interrupt = false
    @files = Hash.new Time.at(0)
    @exceptions = nil
    @last_vcs_update = Time.at 0
  end

  ##
  # Consolidates failed tests +failed+ for the same test class into a single
  # test runner filter.  Also maps failed class to its file regexp.

  def consolidate_failures(failed)
    filters = Hash.new { |h,k| h[k] = [] }

    failed.each do |method, klass|
      failed_file = klass.sub('Test', '').gsub(/(.)([A-Z])/, '\1_?\2')
      filters[failed_file.downcase] << method
    end

    return filters.map do |klass, methods|
      ["\"/^(#{methods.join('|')})$/\"", /#{klass}/]
    end
  end


  ##
  # Selects test files to run that match failures in +failed_file+ based on
  # +updated_files+ and +tests+.
  #
  # Only test files matching +failed_file+ will be returned so the test
  # runner's -n flag will correctly match the failed tests.
  #--
  # failed_test_files must never check for updated files, retest_failed reuses
  # +updated_files+.

  def failed_test_files(failed_file, tests, updated_files)
    return [] if updated_files.empty?

    updated_tests = updated_files.select { |f| f =~ /^test/ }

    tests_to_filter = if updated_files == updated_tests then
                        updated_tests
                      else
                        files = (updated_files + tests).uniq
                        tests_to_filter = map_file_names(files).flatten.uniq
                      end

    return tests_to_filter.select { |test| test =~ failed_file }
  end

  ##
  # Returns a report of remaining failures in +failures+.

  def failure_report(failed)
    out = []
    out << "# failures remain in #{failed.length} files:"
    failed.each do |filter, failed_test|
      tests = @files.keys.select { |file| file =~ /^test.*#{failed_test}/ }
      test = tests.sort_by { |f| f.length }.first

      filter =~ /\((.*)\)/
      filter = $1.split('|')

      out << "#  #{test}:"
      out << "#    #{filter.join "\n#    "}"
    end

    return out.join("\n")
  end

  ##
  # Installs the SIGINT handler.

  def add_sigint_handler
    trap 'INT' do
      if @interrupt then
        puts "# Ok, you really want to quit, doing so"
        exit
      end
      # STDERR.puts "\t#{caller.join "\n\t"}"
      puts "# hit ^C again to quit"
      sleep 1.5 # give them enough time to hit ^C again
      @interrupt = true # if they hit ^C again, 
      raise Interrupt # let the run loop catch it
    end
  end

  ##
  # Maps implementation files to test files.  Returns an Array of one or more
  # Arrays of test filenames.

  def map_file_names(updated)
    tests = []

    updated.each do |filename|
      case filename
      when %r%^lib/(?:.*/)?(.*\.rb)$% then
        impl = $1.gsub '_', '_?'
        found = @files.keys.select do |k|
          k =~ %r%^test/.*#{impl}$%
        end
        tests.push(*found)
      when %r%^test/test_% then
        tests << filename # always run tests
      when %r%^(doc|pkg)/% then
        # ignore
      else
        STDERR.puts "Dunno! #{filename}" if $v or $TESTING
      end
    end

    tests.uniq!

    return [tests]
  end

  ##
  # Resets all file timestamps in the list

  def reset_times
    ago = Time.at 0
    @files.each_key { |file| @files[file] = ago }
  end

  ##
  # Retests failed tests.
  #--
  # Runs through each failure and runs tests matching the failure.  If an
  # implementation file was updated all failed tests should be run.
  #
  # TODO collapse multiple failures in the same file (in test) and use | in
  # the filter.

  def retest_failed(failed, tests)
    puts "# Waiting for changes"

    # -t and -n includes all tests that match either filter, not tests that
    # match both filters, so figure out which TestCase to run from the filename,
    # and use -n on that.
    until failed.empty? do
      sleep 2 unless $TESTING

      updated = updated_files

      # REFACTOR
      failed.map! do |filter, failed_test|
        failed_files = failed_test_files failed_test, tests, updated
        break [filter, failed_test] if failed_files.empty?

        puts "# Rerunning failures: #{failed_files.join ' '}"

        test_filter = " -n #{filter}" unless filter == "'/^(default_test)/'"
        cmd = "#{ruby} -Ilib:test #{failed_files.join ' '}#{test_filter} | unit_diff -u"

        puts "+ #{cmd}"
        result = `#{cmd}`
        puts result
        status = result.split($/).last
        rerun = status =~ / 0 failures, 0 errors/ ? nil : [filter, failed_test]
        puts "# Waiting for changes" if rerun
        rerun # needed for map!
      end

      puts failure_report(failed) if failed.compact! and not failed.empty?
    end
  end

  ##
  # The path to this ruby for running tests.

  def ruby
    ruby = File.join(Config::CONFIG['bindir'],
                     Config::CONFIG['ruby_install_name'])

    unless File::ALT_SEPARATOR.nil? then
      ruby.gsub! File::SEPARATOR, File::ALT_SEPARATOR
    end

    return ruby
  end

  ##
  # Repeatedly scans for updated files and runs their tests.

  def run
    add_sigint_handler

    begin

      loop do
        vcs_update

        files = updated_files
        test files unless files.empty?
        sleep 2
      end
    rescue Interrupt
      @interrupt = false # they didn't hit ^C in time
      puts "# ok, restarting from the top"
      @files.clear
      retry
    end
  end

  ##
  # Runs tests for files in +updated+.  Implementation files are looked up
  # with map_file_names.
  #
  # Returns true if any of the tests ever failed.

  def test(updated)
    ever_failed = false

    # Don't run tests if there's nothing to test.
    all_tests = map_file_names updated
    all_tests = all_tests.map { |tests| tests.empty? ? nil : tests }.compact
    return if all_tests.empty?

    all_tests.each do |files|
      next if files.empty?
      test_files = files.map { |file| "'#{file}'" }.join ', '
      puts '# Testing updated files'
      cmd = "#{ruby} -Ilib:test -e \"[#{test_files}].each { |f| load f }\" | unit_diff -u"
      puts "+ #{cmd}"
      results = `#{cmd}`
      puts results

      if results =~ / 0 failures, 0 errors\Z/ then
        puts '# Passed'
        next
      end

      ever_failed = true

      failed = results.scan(/^\s+\d+\) (?:Failure|Error):\n(.*?)\((.*?)\)/)

      if failed.empty? then
        puts '# Test::Unit exited without a parseable failure or error message.'
        puts '# You probably have a syntax error in your code, or a missing file, or something...'
        puts '# Waiting for changes'
        return true
      end

      failed = consolidate_failures(failed)

      # REFACTOR: I don't think the two routines merit real differences
      retest_failed failed, files

      break
    end

    if ever_failed
      reset_times
    else # We'll immediately test everything, so don't print this out.
      puts '# All passed'
      puts "# Waiting for changes"
    end

    return ever_failed
  end

  ##
  # Returns true or false if the file has been modified or not.  New files are
  # always modified.

  def updated?(file)
    mtime = File.stat(file).mtime
    updated = @files[file] < mtime
    @files[file] = mtime
    return updated
  end

  ##
  # Returns names of files that have been modified since updated_files was
  # last run.  Files and paths can be ignored by setting @exceptions in
  # initialize.

  def updated_files
    updated = []

    Find.find '.' do |f|
      if @exceptions then
        if f =~ @exceptions then
          Find.prune if Kernel.test ?d, f
          next
        end
      end

      Find.prune if f =~ /(?:\.svn|CVS|tmp|public)$/ # prune dirs

      next if File.directory? f
      next if f =~ /(?:swp|~|rej|orig)$/        # temporary/patch files
      next if f =~ /\/\.?#/                     # Emacs autosave/cvs merge files

      f = f.sub(/^\.\//, '')

      updated << f if updated? f
    end

    return updated
  end

  ##
  # Updates the files from the VCS system, if any.

  def vcs_update
    return if $vcs.nil? or Time.now <= @last_vcs_update + $vcstime
    @last_vcs_update = Time.now
    case $vcs
    when 'cvs' then
      system 'cvs up'
    when 'p4' then
      system 'p4 sync'
    when 'svn' then
      system 'svn up'
    else
      puts "# Sorry, I don't know what version control system \"#{$vcs}\" is"
    end
  end

end

