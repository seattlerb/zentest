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

  attr_accessor :files, :files_to_test, :output, :last_mtime if $TESTING

  def initialize
    @files = Hash.new Time.at(0)
    @files_to_test = Hash.new { |h,k| h[k] = [] }
    @exceptions = false
    @libs = '.:lib:test'
    @output = $stderr
    @sleep = 1
  end

  def run
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
        end
      end
    end
  end

  def get_to_green
    until all_good do
      run_tests
      wait_for_changes unless all_good
    end
  end

  def run_tests
    find_files_to_test # failed + changed/affected
    cmd = make_test_cmd(@files_to_test)

    puts cmd

    results = `#{cmd}`

    puts results

    handle_results(results)
  end

  ############################################################
  # Utility Methods, not essential to reading of logic

  def add_sigint_handler
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

  def all_good
    @files_to_test.empty?
  end

  def consolidate_failures(failed)
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
      Find.prune if @exceptions and f =~ @exceptions and test ?d, f
      Find.prune if f =~ /(?:\.svn|CVS|tmp|public|doc|pkg)$/ # prune dirs

      next if test ?d, f
      next if f =~ /(?:swp|~|rej|orig)$/        # temporary/patch files
      next if f =~ /\/\.?#/                     # Emacs autosave/cvs merge files

      filename = f.sub(/^\.\//, '')

      result[filename] = File.stat(filename).mtime
    end
    return result
  end

  def handle_results(results)
    failed = results.scan(/^\s+\d+\) (?:Failure|Error):\n(.*?)\((.*?)\)/)
    @files_to_test = consolidate_failures failed
    @tainted = true unless @files_to_test.empty?
  end

  def has_new_files?
    previous = @last_mtime
    @last_mtime = @files.values.sort.last
    @last_mtime > previous
  end

  def make_test_cmd files_to_test
    cmds = []
    full, partial = files_to_test.partition { |k,v| v.empty? }

    unless full.empty? then
      classes = full.map {|k,v| k}.flatten.join(' ')
      cmds << "#{ruby} -I#{@libs} -e \"%w[#{classes}].each { |f| load f }\" | unit_diff -u"
    end

    partial.each do |klass, methods|
      cmds << "#{ruby} -I#{@libs} #{klass} -n \"/^(#{Regexp.union(*methods).source})$/\" | unit_diff -u" 
    end

    return cmds.join('; ')
  end

  def reset
    @interrupted = @wants_to_quit = false
    @files.clear
    @files_to_test.clear
    @last_mtime = Time.at(0)
    find_files_to_test # failed + changed/affected
    @last_mtime = @files.values.sort.last # FIX
    @tainted = false
  end
  
  def ruby
    ruby = File.join(Config::CONFIG['bindir'],
                     Config::CONFIG['ruby_install_name'])

    unless File::ALT_SEPARATOR.nil? then
      ruby.gsub! File::SEPARATOR, File::ALT_SEPARATOR
    end

    return ruby
  end

  def rerun_all_tests
    reset
    run_tests
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

  def find_files_to_test(files=find_files) # TODO: give better name
    updated = []

    # TODO: keep an mtime at app level and drop the files hash
    files.each do |filename, mtime|
      next if @files[filename] >= mtime

      tests_for_file(filename).each do |f|
        @files_to_test[f] # creates key with default value
      end

      @files[filename] = mtime
    end
  end

  def wait_for_changes
    begin
      sleep @sleep
      find_files_to_test
    end until has_new_files?
  end
end
