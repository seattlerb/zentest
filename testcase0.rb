# This is the good case where there are no missing methods on either side.

require 'test/unit/testcase'

class Blah
  def missingtest; end
  def notmissing1; end
  def notmissing2; end

  # found by zentest on testcase1.rb
  def missingimpl; end
end

class TestBlah < Test::Unit::TestCase
  def setup; end
  def teardown; end

  def test_notmissing1
    assert(true, "a test")
  end
  def test_notmissing2_ext1
    assert(true, "a test")
  end
  def test_notmissing2_ext2
    flunk("a failed test")
  end
  def test_missingimpl; end
  def test_missingtest; end
end
