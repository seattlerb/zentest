#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit/testcase'
require 'test/unit' if $0 == __FILE__
require 'stringio'
require 'autotest'

# NOT TESTED:
#   class_run
#   add_sigint_handler
#   all_good
#   get_to_green
#   reset
#   ruby
#   run
#   run_tests

class Autotest
  def self.clear_hooks
    HOOKS.clear
  end
end

class TestAutotest < Test::Unit::TestCase
  def setup
    @test_class = 'TestBlah'
    @test = 'test/test_blah.rb'
    @impl = 'lib/blah.rb'

    @a = Object.const_get(self.class.name[4..-1]).new
    @a.output = StringIO.new
    @a.files.clear
    @a.files[@impl] = Time.at(1)
    @a.files[@test] = Time.at(2)
    @a.last_mtime = Time.at(2)
  end

  def test_consolidate_failures_experiment
    @a.files.clear
    @a.files['lib/autotest.rb'] = Time.at(1)
    @a.files['test/test_autotest.rb'] = Time.at(2)

    input = [['test_fail1', 'TestAutotest'], ['test_fail2', 'TestAutotest'], ['test_error1', 'TestAutotest'], ['test_error2', 'TestAutotest']]
    result = @a.consolidate_failures input
    expected = { 'test/test_autotest.rb' => %w( test_fail1 test_fail2 test_error1 test_error2 ) }
    assert_equal expected, result
  end

  def test_consolidate_failures_green
    result = @a.consolidate_failures([])
    expected = {}
    assert_equal expected, result
  end

  def test_consolidate_failures_multiple_matches
    @a.files['test/test_blah_again.rb'] = Time.at(42)
    result = @a.consolidate_failures([['test_unmatched', @test_class]])
    expected = {}
    assert_equal expected, result
    expected = "multiple files matched class TestBlah [\"test/test_blah.rb\", \"test/test_blah_again.rb\"].\n"
    assert_equal expected, @a.output.string
  end

  def test_consolidate_failures_no_match
    result = @a.consolidate_failures([['test_blah1', @test_class], ['test_blah2', @test_class], ['test_blah1', 'TestUnknown']])
    expected = {@test => ['test_blah1', 'test_blah2']}
    assert_equal expected, result
    expected = "Unable to map class TestUnknown to a file\n"
    assert_equal expected, @a.output.string
  end

  def test_consolidate_failures_nested_classes
    result = @a.consolidate_failures([['test_blah1', "#{@test_class}::Inner"]])
    expected = {@test => ['test_blah1']}
    assert_equal expected, result
    expected = ""
    assert_equal expected, @a.output.string
  end

  def test_consolidate_failures_red
    result = @a.consolidate_failures([['test_blah1', @test_class], ['test_blah2', @test_class]])
    expected = {@test => ['test_blah1', 'test_blah2']}
    assert_equal expected, result
  end

  # TODO: lots of filename edgecases for find_files_to_test

  def test_find_files_to_test
    @a.last_mtime = Time.at(0)
    assert @a.find_files_to_test(@a.files)

    @a.last_mtime = @a.files.values.sort.last + 1
    assert ! @a.find_files_to_test(@a.files)
  end

  def test_find_files_to_test_dunno
    empty = {}

    files = { "fooby.rb" => Time.at(42) }
    assert @a.find_files_to_test(files)  # we find fooby,
    assert_equal empty, @a.files_to_test # but it isn't something to test
    assert_equal "Dunno! fooby.rb\n", @a.output.string
  end

  def test_find_files_to_test_lib
    # ensure we add test_blah.rb when blah.rb updates
    util_find_files_to_test(@impl, @test => [])
  end

  def test_find_files_to_test_no_change
    empty = {}

    # ensure world is virginal
    assert_equal empty, @a.files_to_test

    # ensure we do nothing when nothing changes...
    files = { @impl => @a.files[@impl] } # same time
    assert ! @a.find_files_to_test(files)
    assert_equal empty, @a.files_to_test
    assert_equal "", @a.output.string

    files = { @impl => @a.files[@impl] } # same time
    assert(! @a.find_files_to_test(files))
    assert_equal empty, @a.files_to_test
    assert_equal "", @a.output.string
  end

  def test_find_files_to_test_test
    # ensure we add test_blah.rb when test_blah.rb itself updates
    util_find_files_to_test(@test, @test => [])
  end

  def test_handle_results
    @a.files_to_test.clear
    @a.files.clear
    @a.files['lib/autotest.rb'] = Time.at(1)
    @a.files['test/test_autotest.rb'] = Time.at(2)
    empty = {}
    assert_equal empty, @a.files_to_test, "must start empty"

    s1 = "Loaded suite -e
Started
............
Finished in 0.001655 seconds.

12 tests, 18 assertions, 0 failures, 0 errors
"

    @a.handle_results(s1)
    assert_equal empty, @a.files_to_test, "must stay empty"

    s2 = "
  1) Failure:
test_fail1(TestAutotest) [./test/test_autotest.rb:59]:
  2) Failure:
test_fail2(TestAutotest) [./test/test_autotest.rb:59]:
  3) Error:
test_error1(TestAutotest):
  3) Error:
test_error2(TestAutotest):
"

    @a.handle_results(s2)
    expected = { "test/test_autotest.rb" => %w( test_fail1 test_fail2 test_error1 test_error2 ) }
    assert_equal expected, @a.files_to_test

    @a.handle_results(s1)
    assert_equal empty, @a.files_to_test
  end

  # TODO BUG /usr/local/bin/ruby -I.:lib:test test/test_rails_autotest.rb -n "/^(test_hooks)$/" | unit_diff -u; /usr/local/bin/ruby -I.:lib:test test/test_autotest.rb -n "/^(test_hooks|test_hooks)$/" | unit_diff -u

  # TODO BUG /usr/local/bin/ruby -I.:lib:test test/test_rails_autotest.rb -n "/^(test_hook|test_hooks)$/" | unit_diff -u; /usr/local/bin/ruby -I.:lib:test test/test_autotest.rb -n "/^(test_hooks|test_hooks)$/" | unit_diff -u

  def test_hook_overlap
    Autotest.clear_hooks

    @a.instance_variable_set :@blah1, false
    @a.instance_variable_set :@blah2, false
    @a.instance_variable_set :@blah3, false

    Autotest.add_hook(:blah) do |at|
      at.instance_variable_set :@blah1, true
    end

    Autotest.add_hook(:blah) do |at|
      at.instance_variable_set :@blah2, true
    end

    Autotest.add_hook(:blah) do |at|
      at.instance_variable_set :@blah3, true
    end

    @a.hook :blah

    assert @a.instance_variable_get(:@blah1), "Hook1 should work on blah"
    assert @a.instance_variable_get(:@blah2), "Hook2 should work on blah"
    assert @a.instance_variable_get(:@blah3), "Hook3 should work on blah"
  end

  def test_hook_response
    Autotest.clear_hooks
    assert ! @a.hook(:blah)

    Autotest.add_hook(:blah) { false }
    assert ! @a.hook(:blah)

    Autotest.add_hook(:blah) { false }
    assert ! @a.hook(:blah)
    
    Autotest.add_hook(:blah) { true  }
    assert @a.hook(:blah)
  end

  def test_make_test_cmd
    ruby_cmd = Config::CONFIG['ruby_install_name']
    f = {
      @test => [],
      'test/test_fooby.rb' => [ 'test_something1', 'test_something2' ]
    }
    expected = [ "/usr/local/bin/#{ruby_cmd} -I.:lib:test -rtest/unit -e \"%w[#{@test}].each { |f| load f }\" | unit_diff -u",
                 "/usr/local/bin/#{ruby_cmd} -I.:lib:test test/test_fooby.rb -n \"/^(test_something1|test_something2)$/\" | unit_diff -u" ].join("; ")

    result = @a.make_test_cmd f
    assert_equal expected, result
  end

  def test_tests_for_file
    assert_equal [@test], @a.tests_for_file(@impl)
    assert_equal [@test], @a.tests_for_file(@test)

    assert_equal ['test/test_unknown.rb'], @a.tests_for_file('test/test_unknown.rb')
#    assert_equal [], @a.tests_for_file('test/test_unknown.rb')
    assert_equal [], @a.tests_for_file('lib/unknown.rb')
    assert_equal [], @a.tests_for_file('unknown.rb')
    assert_equal [], @a.tests_for_file('test_unknown.rb')

#     @a.files.clear
#     @a.files["blah.rb"] = Time.at(1)
#     @a.files["test_blah.rb"] = Time.at(2)
#     @a.last_mtime = Time.at(2)
#    assert_equal ["test_blah.rb"], @a.tests_for_file("test_blah.rb")
#    assert_equal ["test_blah.rb"], @a.tests_for_file("blah.rb")
  end

  def util_find_files_to_test(f, expected)
    t = @a.last_mtime + 1
    files = { f => t }

    assert @a.find_files_to_test(files)
    assert_equal expected, @a.files_to_test
    assert_equal t, @a.files[f]
    assert_equal "", @a.output.string
  end
end
