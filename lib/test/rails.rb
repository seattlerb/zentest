require 'test/unit'

$TESTING = true

##
# Test::Rails is a replacement for Rails' testing.
#
# = Features
#
# * Functional tests are split into Controller tests and View tests.
#   * Helps decouple views from controllers.
#   * Allows you to test a single partial.
#   * Less garbage on your screen when assert_tag goes wrong.
# * An auditing script analyzes missing assertions in your controllers and
#   views.
# * View testing assertion library.
#
# = Using Test::Rails
#
# First, be sure you have ZenTest installed.
#
# Add this line to test/test_helper.rb:
#
#   require 'test/rails'
#
# Add this line to your Rakefile:
#
#   require 'test/rails/rake_tasks'
#
# TODO: How to split test/functional/* into test/view/* and test/controller/*
# TODO: How to audit your controller/view tests for missing assert_assigns
# TODO: List differences in rake tasks

module Test::Rails; end

class Object # :nodoc:
  def self.path2class(klassname)
    klassname.split('::').inject(Object) { |k,n| k.const_get n }
  end
end

require 'test/rails/controller_test_case'
require 'test/rails/ivar_proxy'
require 'test/rails/view_test_case'

