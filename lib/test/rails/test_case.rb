##
# Test::Rails::TestCase is an abstract test case for Test::Rails test cases.
#--
# Eventually this will hold the fixture setup stuff.

class Test::Rails::TestCase < Test::Unit::TestCase

  undef_method :default_test

  # Set defaults because Rails has poor ones (and these don't inherit properly)
  self.use_transactional_fixtures = true
  self.use_instantiated_fixtures = false

end

