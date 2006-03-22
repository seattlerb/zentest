$TESTING = defined? $TESTING

require 'find'

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
# Autotest uses a simple naming scheme to figure out how to map implementation
# files to test files following the Test::Unit naming scheme.
#
# * Test files must be stored in test/
# * Test files names must start with test_
# * Test classes must start with Test
# * Implementation files must be stored in lib/
# * Implementation files must match up with a test file named
#   test_.*implementation.rb

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
  end

  ##
  # Maps failed class +klass+ to test files in +tests+ that have been updated.

  def failed_test_files(klass, tests)
    failed_klass = klass.sub('Test', '').gsub(/(.)([A-Z])/, '\1_?\2').downcase
    # tests that match this failure
    failed_files = tests.select { |test| test =~ /#{failed_klass}/ }
    # updated implementations that match this failure
    changed_impls = @files.keys.select do |file|
      file =~ %r%^lib.*#{failed_klass}.rb$% and updated? file
    end
    tests_to_run = map_file_names(changed_impls).flatten
    # add updated tests
    failed_files.each { |f| tests_to_run << f if updated? f }
    return tests_to_run.uniq
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
        STDERR.puts "Dunno! #{filename}" # What are you trying to pull?
      end
    end

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

  def retest_failed(failed, tests)
    # -t and -n includes all tests that match either filter, not tests that
    # match both filters, so figure out which TestCase to run from the filename,
    # and use -n on that.
    until failed.empty? do
      sleep 5 unless $TESTING

      failed.map! do |method, klass|
        failed_files = failed_test_files klass, tests
        break [method, klass] if failed_files.empty?
        puts "# Rerunning failures: #{failed_files.join ' '}"
        filter = "-n #{method} " unless method == 'default_test'
        cmd = "ruby -Ilib:test -S testrb #{filter}#{failed_files.join ' '} | unit_diff -u"
        puts "+ #{cmd}"
        system(cmd) ? nil : [method, klass] # clever
      end

      failed.compact!
    end
  end

  ##
  # Repeatedly scans for updated files and runs their tests.

  def run
    trap 'INT' do
      if @interrupt then
        puts "# Ok, you really want to quit, doing so"
        exit
      end
      puts "# hit ^C again to quit"
      sleep 1.5 # give them enough time to hit ^C again
      @interrupt = true # if they hit ^C again, 
      raise Interrupt # let the run loop catch it
    end
      
    begin
      last_update = Time.at 0

      loop do
        if $vcs and Time.now > last_update + $vcstime then
          last_update = Time.now
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

        files = updated_files
        test files unless files.empty?
        sleep 5
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

    map_file_names(updated).each do |tests|
      next if tests.empty?
      puts '# Testing updated files'
      cmd = "ruby -Ilib:test -e '#{tests.inspect}.each { |f| load f }' | unit_diff -u"
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
        puts '# You probably have a syntax error in your code.'
        puts '# I\'ll retry in 10 seconds'
        sleep 10
        redo
      end

      retest_failed failed, tests
    end

    reset_times if ever_failed

    puts '# All passed'

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
      next if File.directory? f
      next if f =~ /(?:swp|~|rej|orig)$/ # temporary/patch files
      next if f =~ %r%/\.#% # Emacs autosaved/cvs merge files
      next if f =~ %r%/(?:.svn|CVS)/% # version control files
      next if f =~ @exceptions unless @exceptions.nil? # custom exceptions
      f = f.sub(/^\.\//, '') # trim the ./ that Find gives us
      updated << f if updated? f
    end

    return updated
  end

end

