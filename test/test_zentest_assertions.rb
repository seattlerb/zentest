require 'test/unit'
require 'test/zentest_assertions'

class TestZenTestAssertions < Test::Unit::TestCase

  def test_assert_empty
    assert_empty []

    e = assert_raise Test::Unit::AssertionFailedError do
      assert_empty [true]
    end

    assert_equal "[true] expected to be empty.", e.message
  end

  def test_assert_include
    assert_include true, [true]

    e = assert_raise Test::Unit::AssertionFailedError do
      assert_include false, [true]
    end

    assert_equal "[true] does not include false.", e.message
  end

  def test_assert_in_epsilon
      assert_in_epsilon 1.234, 1.234, 0.0001

    e = assert_raise Test::Unit::AssertionFailedError do
      assert_in_epsilon 1.235, 1.234, 0.0001
    end

    assert_equal "<1.235> expected to be within <0.0001> of <1.234>, was
<0.000809716599190374>", e.message
  end

  def test_deny
    deny false
    deny nil

    e = assert_raise Test::Unit::AssertionFailedError do
      deny true
    end

    assert_equal "<true> is not false or nil.", e.message
  end

  def test_deny_empty
    deny_empty [true]

    e = assert_raise Test::Unit::AssertionFailedError do
      deny_empty []
    end

    assert_equal "[] expected to have stuff.", e.message
  end

  def test_deny_equal
    deny_equal true, false
    
    assert_raise Test::Unit::AssertionFailedError do
      deny_equal true, true
    end
  end

  def test_deny_include
    deny_include false, [true]

    e = assert_raise Test::Unit::AssertionFailedError do
      deny_include true, [true]
    end

    assert_equal "[true] includes true.", e.message
  end

  def test_deny_nil
    deny_nil false

    assert_raise Test::Unit::AssertionFailedError do
      deny_nil nil
    end
  end

  def test_util_capture
    out, err = util_capture do
      puts 'out'
      $stderr.puts 'err'
    end

    assert_equal "out\n", out.string
    assert_equal "err\n", err.string
  end

end

