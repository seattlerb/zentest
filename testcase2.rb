require 'test/unit/testcase'

module Something
  class Blah
    def missingtest; end
    def notmissing1; end
    def notmissing2; end
  end
end

module TestSomething
  class TestBlah < Test::Unit::TestCase
    def test_notmissing1; end
    def test_notmissing2_ext1; end
    def test_notmissing2_ext2; end
    def test_missingimpl; end
  end
end

