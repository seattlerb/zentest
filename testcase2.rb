require 'test/unit/testcase'

module Something2
  class Blah2
    def missingtest; end
    def notmissing1; end
    def notmissing2; end
  end
end

module TestSomething2
  class TestBlah2 < Test::Unit::TestCase
    def test_notmissing1; end
    def test_notmissing2_ext1; end
    def test_notmissing2_ext2; end
    def test_missingimpl; end
  end
end

