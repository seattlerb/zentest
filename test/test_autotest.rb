#!/usr/local/bin/ruby -w

$TESTING = true

require 'test/unit' unless defined? $ZENTEST and $ZENTEST
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

class TestAutotest < Test::Unit::TestCase
  def setup
    @a = Autotest.new
    @a.files = {
      'lib/blah.rb' => 1,
      'test/test_blah.rb' => 2,
    }
    @a.files.default = 0
    @a.output = StringIO.new
  end

  def test_consolidate_failures_experiment
    @a.files = {
      'lib/autotest.rb' => 1,
      'test/test_autotest.rb' => 2,
    }
    @a.files.default = 0
    input = [["test_fail1", "TestAutotest"], ["test_fail2", "TestAutotest"], ["test_error1", "TestAutotest"], ["test_error2", "TestAutotest"]]
    result = @a.consolidate_failures input
    expected = { "test/test_autotest.rb" => %w( test_fail1 test_fail2 test_error1 test_error2 ) }
    assert_equal expected, result
  end

  def test_consolidate_failures_green
    result = @a.consolidate_failures([])
    expected = {}
    assert_equal expected, result
  end

  def test_consolidate_failures_multiple_matches
    @a.files['test/test_blah_again.rb'] = 42
    result = @a.consolidate_failures([['test_unmatched', 'TestBlah']])
    expected = {}
    assert_equal expected, result
    expected = "multiple files matched class TestBlah [\"test/test_blah.rb\", \"test/test_blah_again.rb\"].\n"
    assert_equal expected, @a.output.string
  end

  def test_consolidate_failures_no_match
    result = @a.consolidate_failures([['test_blah1', 'TestBlah'], ['test_blah2', 'TestBlah'], ['test_blah1', 'TestUnknown']])
    expected = {'test/test_blah.rb' => ['test_blah1', 'test_blah2']}
    assert_equal expected, result
    expected = "Unable to map class TestUnknown to a file\n"
    assert_equal expected, @a.output.string
  end

  def test_consolidate_failures_red
    result = @a.consolidate_failures([['test_blah1', 'TestBlah'], ['test_blah2', 'TestBlah']])
    expected = {'test/test_blah.rb' => ['test_blah1', 'test_blah2']}
    assert_equal expected, result
  end

  def test_handle_results
    @a.files = {
      'lib/autotest.rb' => 1,
      'test/test_autotest.rb' => 2,
    }
    @a.files.default = 0

    s = "Loaded suite -e
Started
............
Finished in 0.001655 seconds.

12 tests, 18 assertions, 0 failures, 0 errors
"

    @a.handle_results(s)
    empty = {}
    assert_equal empty, @a.files_to_test

    s = "
  1) Failure:
test_fail1(TestAutotest) [./test/test_autotest.rb:59]:
  2) Failure:
test_fail2(TestAutotest) [./test/test_autotest.rb:59]:
  3) Error:
test_error1(TestAutotest):
  3) Error:
test_error2(TestAutotest):
"

    @a.handle_results(s)
    expected = { "test/test_autotest.rb" => %w( test_fail1 test_fail2 test_error1 test_error2 ) }
    assert_equal expected, @a.files_to_test
  end

  def test_make_test_cmd
    f = {
      'test/test_blah.rb' => [],
      'test/test_fooby.rb' => [ 'test_something1', 'test_something2' ]
    }
    expected = [ "/usr/local/bin/ruby -I.:lib:test -e \"%w[test/test_blah.rb].each { |f| load f }\" | unit_diff -u",
                 "/usr/local/bin/ruby -I.:lib:test test/test_fooby.rb -n \"/^(test_something1|test_something2)$/\" | unit_diff -u" ].join("; ")

    result = @a.make_test_cmd f
    assert_equal expected, result
  end

  def test_update_files_to_test_dunno
    empty = {}

    files = { "fooby.rb" => 42 }
    @a.update_files_to_test files
    result = @a.files_to_test
    assert_equal empty, result
    assert_equal "Dunno! fooby.rb\n", @a.output.string
  end

  # TODO: lots of filename edgecases for update_files_to_test

  def test_update_files_to_test_lib
    # ensure we add test_blah.rb when blah.rb updates
    util_update_files_to_test("lib/blah.rb", 'test/test_blah.rb' => [])
  end

  def test_update_files_to_test_no_change
    empty = {}

    # ensure world is virginal
    assert_equal empty, @a.files_to_test

    # ensure we do nothing when nothing changes...
    files = { "lib/blah.rb" => @a.files["lib/blah.rb"] } # same time
    @a.update_files_to_test files
    result = @a.files_to_test
    assert_equal empty, result
    assert_equal "", @a.output.string

    files = { "lib/blah.rb" => @a.files["lib/blah.rb"] } # same time
    @a.update_files_to_test files
    result = @a.files_to_test
    assert_equal empty, result
    assert_equal "", @a.output.string
  end

  def test_update_files_to_test_test
    # ensure we add test_blah.rb when test_blah.rb itself updates
    util_update_files_to_test("test/test_blah.rb", 'test/test_blah.rb' => [])
  end

  def util_update_files_to_test(f, expected)
    t = @a.files[f] + 1
    files = { f => t }
    @a.update_files_to_test files
    result = @a.files_to_test

    assert_equal expected, result
    assert_equal t, @a.files[f]
    assert_equal "", @a.output.string
  end
end
