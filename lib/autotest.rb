$TESTING = defined? $TESTING

require 'find'

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
    klass_name = /#{klass.gsub(/(.)([A-Z])/, '\1_\2').downcase}/
    failed_files = tests.select { |test| test =~ klass_name }
    return failed_files.reject { |f| not updated? f }
  end

  ##
  # Maps implementation files to test files.  Returns an Array of one or more
  # Arrays of test filenames.

  def map_file_names(updated)
    tests = []

    updated.each do |filename|
      filename.sub!(/^\.\//, '') # trim the ./ that Find gives us

      case filename
      when %r%^lib/(?:.*/)?(.*\.rb)$% then
        tests << "test/test_#{$1}" # lib/*/*rb -> test/test_*rb
      when %r%^test/test_% then
        tests << filename # always run tests
      else
        STDERR.puts "Dunno! #{filename}" # What are you trying to pull?
      end
    end

    return [tests]
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
        cmd = "ruby -Ilib:test -S testrb #{filter}#{failed_files.join ' '}"
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
      sleep 1 # give them enough time to hit ^C again
      @interrupt = true # if they hit ^C again, 
      raise Interrupt # let the run loop catch it
    end
      
    begin
      loop do
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

  def test(updated)
    map_file_names(updated).each do |tests|
      next if tests.empty?
      puts '# Testing updated files'
      cmd = "ruby -Ilib:test -e '#{tests.inspect}.each { |f| load f }'"
      puts "+ #{cmd}"
      results = `#{cmd}`
      puts results

      if results =~ / 0 failures, 0 errors\Z/ then
        puts '# Passed'
        next
      end

      failed = results.scan(/^\s+\d+\) (?:Failure|Error):\n(.*?)\((.*?)\)/)

      if failed.empty? then
        puts '# Test::Unit died, you did a really bad thing, retrying in 10'
        sleep 10
        redo
      end

      retest_failed failed, tests
    end

    puts '# All passed'
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
      next if f =~ %r%/(?:.svn|CVS)/% # version control files
      next if f =~ @exceptions unless @exceptions.nil? # custom exceptions
      updated << f if updated? f
    end

    return updated
  end

end

