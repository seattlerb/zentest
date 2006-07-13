$TESTING = defined? $TESTING

require 'find'
require 'rbconfig'

$TESTING = false unless defined? $TESTING

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

  attr_accessor :files, :files_to_test, :output if $TESTING

  def initialize
    @files = Hash.new Time.at(0)
    @files_to_test = Hash.new { |h,k| h[k] = [] }
    @libs = '.:lib:test'
    @output = $stderr
    @sleep = 1
  end

  def run
    log_method
    reset
    add_sigint_handler

    loop do # ^c handler
      begin
        get_to_green
      rescue Interrupt
        if @wants_to_quit then
          break
        else
          reset
        end
      end
    end
  end

  def get_to_green # TODO: think about inlining this
    log_method
    loop do
      log 'status', 'running all tests'
      reset
      run_tests # run all tests each full pass
      @last_mtime = @files.values.sort.last
      run_tests until all_good
    end
  end

  def run_tests # TODO: and possibly rename this get_to_green
    log_method
    update_files_to_test # failed + changed/affected

    cmd = make_test_cmd @files_to_test

    log 'data', "@files_to_test = #{@files_to_test.inspect}"
    log 'status', 'Testing updated files'
    log 'cmd', cmd
    results = `#{cmd}`

    puts results

    handle_results(results)
  end

  def all_good
    log_method
    unless @files_to_test.empty? then
      newest = nil
      loop do
        update_files_to_test
        newest = @files.values.sort.last
        break if newest > @last_mtime
        #log 'status', "waiting because of #{newest} > #{@last_mtime} in #{@files_to_test.inspect}"
        sleep @sleep # TODO unless testing ?
      end
      @last_mtime = newest
    end
    @files_to_test.empty?
  end

  ############################################################
  # Utility Methods, not essential to reading of logic

  def log(cat, msg)
    @output.puts "# AUTOTEST:#{cat}:#{msg}" unless $TESTING
  end

  def log_method
    meth = caller[0].split(/:/).last[4..-2]
    log 'meth', meth
  end

  def add_sigint_handler
    log_method
    trap 'INT' do
      if @interrupted then
        puts "# quitting"
        @wants_to_quit = true
      else
        puts "quitting"
        exit # HACK
        puts "# hit ^C again to quit"
        # FIX: shouldn't sleep come AFTER @interrupted = true?
        sleep 1.5                       # give them enough time to hit ^C again
        @interrupted = true             # if they hit ^C again, 
        raise Interrupt                 # let the run loop catch it
      end
    end
  end

  def consolidate_failures(failed)
    log_method
    filters = Hash.new { |h,k| h[k] = [] }

    failed.each do |method, klass|
      failed_file_name = klass.gsub(/(.)([A-Z])/, '\1_?\2') # HACK: was stripping of Test
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
      Find.prune if f =~ /(?:\.svn|CVS|tmp|public)$/ # prune dirs

      next if File.directory? f
      next if f =~ /(?:swp|~|rej|orig)$/        # temporary/patch files
      next if f =~ /\/\.?#/                     # Emacs autosave/cvs merge files

      filename = f.sub(/^\.\//, '')
      mtime = File.stat(filename).mtime
      result[filename] = mtime
    end
    return result
  end

  def handle_results(results)
    log_method

    # TODO: get rid of this
    if results =~ / 0 failures, 0 errors\Z/ then
      log 'status', 'Passed'
      return
    end

    failed = results.scan(/^\s+\d+\) (?:Failure|Error):\n(.*?)\((.*?)\)/)

    # TODO: get rid of this
    if failed.empty? then
      log 'status', 'tests exited without a parseable failure or error message.'
      log 'status', 'check for a syntax error in your code, or something...'
      return
    end

    log 'data', "@files = #{@files.inspect}"
    log 'data', "failed = #{failed.inspect}"
    log 'data', "old @files_to_test = #{@files_to_test.inspect}"
    @files_to_test = consolidate_failures failed
    log 'data', "new @files_to_test = #{@files_to_test.inspect}"
  end

  def make_test_cmd files_to_test
    cmds = []
    full, partial = files_to_test.partition { |k,v| v.empty? }

    unless full.empty? then
      classes = full.map {|k,v| k}.flatten.join(' ')
      cmds << "#{ruby} -I#{@libs} -e \"%w[#{classes}].each { |f| load f }\" | unit_diff -u"
    end

    partial.each do |klass, methods|
      cmds << "#{ruby} -I#{@libs} #{klass} -n \"#{Regexp.union(*methods).inspect}\" | unit_diff -u" 
    end

    return cmds.join('; ')
  end

  def reset
    log_method
    @interrupted = @wants_to_quit = false
    @files.clear
    @files_to_test.clear
    @last_mtime = Time.at(0)
    update_files_to_test # failed + changed/affected
  end
  
  def ruby
    ruby = File.join(Config::CONFIG['bindir'],
                     Config::CONFIG['ruby_install_name'])

    unless File::ALT_SEPARATOR.nil? then
      ruby.gsub! File::SEPARATOR, File::ALT_SEPARATOR
    end

    return ruby
  end

  def update_files_to_test(files=find_files)
    updated = []

    files.each do |filename, mtime|
      if @files[filename] < mtime then
        # TODO: keep an mtime at app level and drop the files hash
        case filename
        when %r%^lib/(?:.*/)?(.*\.rb)$% then
          impl = $1.gsub '_', '_?'
          found = @files.keys.select do |k|
            k =~ %r%^test/.*#{impl}$%
          end
          found.each do |f|
            @files_to_test[f] # creates key with default value
          end
        when %r%^test/test_% then
          @files_to_test[filename] # creates key with default value
        when %r%^(doc|pkg)/% then
          # ignore
        else
          @output.puts "Dunno! #{filename}" if $v or $TESTING
        end
        @files[filename] = mtime
      end
    end
  end
end
