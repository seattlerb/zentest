# :nodoc:
#
# Author:: Nathaniel Talbott.
# Copyright:: Copyright (c) 2000-2002 Nathaniel Talbott. All rights reserved.
# License:: Ruby license.

require 'test/unit/testresult'
require 'test/unit/ui/testrunnermediator'
require 'test/unit/ui/testrunnerutilities'

# Runs a Test::Unit::TestSuite on the console.
class ZenTestRunner
  extend Test::Unit::UI::TestRunnerUtilities

  # Creates a new ZenTestRunner and runs the suite.
  def ZenTestRunner.run(suite)
    return new(suite).start
  end

  # Creates a new ZenTestRunner for running the passed
  # suite. If quiet_mode is true, the output while
  # running is limited to progress dots, errors and
  # failures, and the final result. io specifies
  # where runner output should go to; defaults to
  # STDERR.
  def initialize(suite, quiet_mode=false, io=STDERR)
    if (suite.respond_to?(:suite))
      @suite = suite.suite
    else
      @suite = suite
    end
    @allfaults = []
    @quiet_mode = quiet_mode
    @io = io
    @result = Test::Unit::TestResult.new
  end

  # Begins the test run.
  def start
    setup_mediator
    attach_to_mediator
    return start_mediator
  end

  private
  def setup_mediator # :nodoc:
    @mediator = create_mediator(@suite)
    suite_name = @suite.to_s
    if ( @suite.kind_of?(Module) )
      suite_name = @suite.name
    end
    @io.puts("Loaded suite #{suite_name}") if (!@quiet_mode)
  end
  def create_mediator(suite) # :nodoc:
    return Test::Unit::UI::TestRunnerMediator.new(suite)
  end
  def attach_to_mediator # :nodoc:
    @io.puts "Attaching"
    @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::FAULT_ADDED, &method(:add_fault))
    @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::RESULT_CHANGED, &method(:result_changed))
    @mediator.add_listener(Test::Unit::UI::TestRunnerMediator::STATUS_CHANGED, &method(:update_status))
  end
  def start_mediator # :nodoc:
    return @mediator.run_suite
  end
  def add_fault(fault) # :nodoc:
    type = fault.class.name.split(/::/)[-1][0].chr
    @io.write(type)
    @allfaults.push(fault)
  end
  def result_changed(result) # :nodoc:
    @result = result
  end
  def update_status(status) # :nodoc:
    if ( status.type == Test::Unit::UI::Status::STARTED_RUNNING )
      @io.puts( status.message ) if (!@quiet_mode)
    elsif ( status.type == Test::Unit::UI::Status::FINISHED_TEST )
      @io.write(".")
    elsif ( status.type == Test::Unit::UI::Status::FINISHED_RUNNING )

      @io.puts
      count = 1
      @allfaults.each { |fault|
	@io.printf("%3d) %s\n", count, fault.long_display)
	count += 1
      }

      @io.puts
      @io.puts( status.message ) if (!@quiet_mode)
      @io.puts( @result )
    end
  end
end

def run_all_tests_with(runnerclass)
  if (!Test::Unit::UI::TestRunnerMediator.run?)
    suite_name = $0.sub(/\.rb$/, '')
    suite = Test::Unit::TestSuite.new(suite_name)
    test_classes = []
    ObjectSpace.each_object(Class) {
      | klass |
      test_classes << klass if (Test::Unit::TestCase > klass)
    }

    if ARGV.empty?
      test_classes.each {|klass| suite.add(klass.suite)}
    else
      tests = test_classes.map { |klass| klass.suite.tests }.flatten
      criteria = ARGV.map { |arg| (arg =~ %r{^/(.*)/$}) ? Regexp.new($1) : arg}
      criteria.each {
	| criterion |
	if (criterion.instance_of?(Regexp))
	  tests.each { |test| suite.add(test) if (criterion =~ test.name) }
	elsif (/^A-Z/ =~ criterion)
	  tests.each { |test| suite.add(test) if (criterion == test.type.name) }
	else
	  tests.each { |test| suite.add(test) if (criterion == test.method_name) }
	end
      }
    end
    runnerclass.run(suite)
  end
end
public :run_all_tests_with

if __FILE__ == $0
  ZenTestRunner.start_command_line_test
end
