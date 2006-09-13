##
# Test::Rails::TestCase is an abstract test case for Test::Rails test cases.
#--
# Eventually this will hold the fixture setup stuff.

class Test::Rails::TestCase < Test::Unit::TestCase

  undef_method :default_test

end

