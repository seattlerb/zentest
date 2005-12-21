require 'test/unit/testcase'

class Blah1
  def missingtest; end
  def notmissing1; end
  def notmissing2; end
end

class TestBlah1 < Test::Unit::TestCase
  def test_notmissing1; end
  def test_notmissing2_ext1; end
  def test_notmissing2_ext2; end
  def test_missingimpl; Blah1.new.missingimpl; end
end
