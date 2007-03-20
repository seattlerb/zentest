# -*- ruby -*-

# This is an example of how to change the mappings of file that
# changed to tests to run for a project.
#
# This project has tests in lib/test that we don't want autotest to
# run. Also, any change will run all the tests.

module Autotest::Fixtures
  Autotest.add_hook :initialize do  |at|
    at.test_mappings['^test/fixtures/(.*)s.yml'] = proc { |filename, matches|
      at.files_matching /test\/\w+\/#{matches[1]}(_\w+)?.*_test.rb$/
    }
  end
end
