#!/usr/local/bin/ruby -w

require 'test/unit'

$TESTING = true

require 'unit_diff'

class TestUnitDiff < Test::Unit::TestCase

  def setup
    @diff = UnitDiff.new
  end

  def test_input
    input = "Loaded suite ./blah\nStarted\nFF\nFinished in 0.035332 seconds.\n\n  1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n<\"line1\\nline2\\nline3\\n\"> expected but was\n<\"line4\\nline5\\nline6\\n\">.\n\n  2) Failure:\ntest_test2(TestBlah) [./blah.rb:29]:\n<\"line1\"> expected but was\n<\"line2\\nline3\\n\\n\">.\n\n2 tests, 2 assertions, 2 failures, 0 errors\n"

    # TODO: I think I'd like a separate footer array as well
    expected = [
                ["Loaded suite ./blah\n", "Started\n", "FF\n", "Finished in 0.035332 seconds.\n"],
                [
                 ["  1) Failure:\n", "test_test1(TestBlah) [./blah.rb:25]:\n", "<\"line1\\nline2\\nline3\\n\"> expected but was\n", "<\"line4\\nline5\\nline6\\n\">.\n"],
                 ["  2) Failure:\n", "test_test2(TestBlah) [./blah.rb:29]:\n", "<\"line1\"> expected but was\n", "<\"line2\\nline3\\n\\n\">.\n"],
                 ],
                ["\n", "2 tests, 2 assertions, 2 failures, 0 errors\n"]
               ]

    assert_equal expected, @diff.input(input)
  end

  def test_parse_diff1
    input = ["  1) Failure:\n",
             "test_test1(TestBlah) [./blah.rb:25]:\n",
             "<\"line1\\nline2\\nline3\\n\"> expected but was\n",
             "<\"line4\\nline5\\nline6\\n\">.\n"
            ]

    expected = [["  1) Failure:\n", "test_test1(TestBlah) [./blah.rb:25]:\n"], ["line1\\nline2\\nline3\\n"], ["line4\\nline5\\nline6\\n"]]

    assert_equal expected, @diff.parse_diff(input)
  end

  def test_parse_diff2
    input = ["  2) Failure:\n",
             "test_test2(TestBlah) [./blah.rb:29]:\n",
             "<\"line1\"> expected but was\n",
             "<\"line2\\nline3\\n\\n\">.\n"
            ]

    expected = [["  2) Failure:\n",
                 "test_test2(TestBlah) [./blah.rb:29]:\n"],
                ["line1"],
                ["line2\\nline3\\n\\n"]
               ]

    assert_equal expected, @diff.parse_diff(input)
  end

  def test_parse_diff3
    input = [" 13) Failure:\n",
             "test_case_stmt(TestRubyToRubyC) [./r2ctestcase.rb:1198]:\n",
             "Unknown expected data.\n",
             "<false> is not true.\n"]

    expected = [[" 13) Failure:\n", "test_case_stmt(TestRubyToRubyC) [./r2ctestcase.rb:1198]:\n", "Unknown expected data.\n"], ["<false> is not true.\n"], nil]

    assert_equal expected, @diff.parse_diff(input)
  end

  def test_unit_diff1
    input = "Loaded suite ./blah\nStarted\nF\nFinished in 0.035332 seconds.\n\n  1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n<\"line1\\nline2\\nline3\\n\"> expected but was\n<\"line4\\nline5\\nline6\\n\">.\n\n1 tests, 1 assertions, 1 failures, 0 errors\n"

    expected = "Loaded suite ./blah\nStarted\nF\nFinished in 0.035332 seconds.\n\n1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n1,3c1,3\n< line1\n< line2\n< line3\n---\n> line4\n> line5\n> line6\n\n1 tests, 1 assertions, 1 failures, 0 errors"

    assert_equal expected, @diff.unit_diff(input)
  end

  def test_unit_diff2
    input = "Loaded suite ./blah\nStarted\nFF\nFinished in 0.035332 seconds.\n\n  1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n<\"line1\\nline2\\nline3\\n\"> expected but was\n<\"line4\\nline5\\nline6\\n\">.\n\n  2) Failure:\ntest_test2(TestBlah) [./blah.rb:29]:\n<\"line1\"> expected but was\n<\"line2\\nline3\\n\\n\">.\n\n2 tests, 2 assertions, 2 failures, 0 errors\n"

    expected = "Loaded suite ./blah\nStarted\nFF\nFinished in 0.035332 seconds.\n\n1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n1,3c1,3\n< line1\n< line2\n< line3\n---\n> line4\n> line5\n> line6\n\n2) Failure:\ntest_test2(TestBlah) [./blah.rb:29]:\n1c1,3\n< line1\n\\ No newline at end of file\n---\n> line2\n> line3\n>\n\n2 tests, 2 assertions, 2 failures, 0 errors"

    assert_equal expected, @diff.unit_diff(input)
  end

  def test_unit_diff3
    input = " 13) Failure:\ntest_case_stmt(TestRubyToRubyC) [./r2ctestcase.rb:1198]:\nUnknown expected data.\n<false> is not true.\n"

    expected = "13) Failure:\ntest_case_stmt(TestRubyToRubyC) [./r2ctestcase.rb:1198]:\nUnknown expected data.\n<false> is not true."

    assert_equal expected, @diff.unit_diff(input)
  end

end

