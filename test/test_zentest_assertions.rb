require 'test/unit'
require 'test/zentest_assertions'

class AssertionsTest < Test::Unit::TestCase

  def test_assert_empty
    assert_empty []

    assert_raise Test::Unit::AssertionFailedError do
      assert_empty [true]
    end
  end

  def test_deny
    deny false
    deny nil

    assert_raise Test::Unit::AssertionFailedError do
      deny true
    end
  end

  def test_deny_equal
    deny_equal true, false
    
    assert_raise Test::Unit::AssertionFailedError do
      deny_equal true, true
    end
  end

  def test_deny_empty
    deny_empty [true]

    assert_raise Test::Unit::AssertionFailedError do
      deny_empty []
    end
  end

  def test_assert_includes
    assert_includes [true], true

    assert_raise Test::Unit::AssertionFailedError do
      assert_includes [true], false
    end
  end

  def test_deny_includes
    deny_includes [true], false

    assert_raise Test::Unit::AssertionFailedError do
      deny_includes [true], true
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

