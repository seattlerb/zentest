require 'test/unit'
require 'test_help' # hopefully temporary, required for Test::Rails to work
                    # until we get rid of test_help so Test::Unit::TestCase
                    # is kept virgin.

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
# Right before you require 'test_help', so your test/test_helper.rb looks like
# this:
#
#   ENV["RAILS_ENV"] = "test"
#   require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
#   require 'test/rails'
#   require 'test_help'
#   ...
#
#--
# This lets us undo whatever horrors test_help performs upon
# Test::Unit::TestCase.
#
# TODO Have people switch from Test::Unit::TestCase to Test::Rails::TestCase
# or similar so we can keep Test::Unit::TestCase virgin.
#++
#
# Add this line to your Rakefile after you require 'test/rails/rake_tasks':
#
#   require 'test/rails/rake_tasks'
#
# So your Rakefile looks like this:
#
#   ...
#   require 'tasks/rails'
#   require 'test/rails/rake_tasks'
#
# = Switching your tests to Test::Rails
#
# Test::Rails splits functional tests into view tests and controller tests.
#
# To take maximum advantage of Test::Rails you will need to split your view
# assertions away from your controller assertions.
#
# == Creating view tests
#
# TODO Describe where view tests live (test/views)
# TODO Describe how view tests are named (test/views/route_view_test.rb)
#
# A typical view test looks like this:
#
#   require 'test/test_helper'
#   
#   # We are testing RouteController's views
#   class RouteViewTest < Test::Rails::ViewTestCase
#     
#     fixtures :users, :routes, :points, :photos
#     
#     # testing the view for the delete action of RouteController
#     def test_delete
#       # Instance variables necessary for this view
#       assigns[:loggedin_user] = users(:herbert)
#       assigns[:route] = routes(:work)
#       
#       # render this view
#       render
#       
#       # assert everything is as it should be
#       assert_links_to "/route/flickr_refresh/#{routes(:work).id}"
#       
#       form_url = '/route/destroy'
#       assert_post_form form_url
#       assert_input form_url, :hidden, :id
#       assert_submit form_url, 'Delete!'
#       assert_links_to "/route/show/#{routes(:work).id}", 'No, I do not!'
#     end
#     
#     # ...
#     
#   end
#
# Here are the differences step by step:
#
# All view tests are a subclass of Test::Rails::ViewTestCase.  The name of the
# subclass must match the controller this view depends upon.  ViewTestCase
# takes care of all the setup necessary for running the tests.
#
# Fixtures work just like they do in a functional test.
#
# The +test_delete+ method is named after the delete method in
# RouteController.  The ViewTestCase#render method looks at the name of the
# test and tries to figure out which view file to use, so naming tests after
# actions will save you headaches and typing.
#
# +controller+ is a proxy for the RouteController instance this test case uses.
# The call +assigns[:route] = routes(:work)+ sets the +@route+ instance
# variable to +routes(:work)+ just like you would in RouteController#delete.
#
# The call to render is the equivalent to a functional tests' process/get/post
# methods.  It makes several assumptions, so be sure to read carefully.
#
# +render+ looks at the name of the test, test_delete, and removes the "test_"
# then looks for a view file matching that name in app/views/route.  So this
# render will try to render the file app/views/route/delete.rhtml.
#
# You can give render all of the render flags listed in the Rails API.
#
# By default render has the added option :layout => false, so if you need
# layout set :layout => true.
#
# render will try to figure out the correct view file for the action even if
# you add extra naming bits to your test like test_delete_logged_out.  Read
# ViewTestCase#render for the full description of how render goes looking for
# templates to render.
#
# ViewTestCase has a vastly expanded assertion library to help you out with
# testing.  See ViewTestCase for all the helpful assertions you can use in
# your view tests.
#
# == Creating controller tests
#
# TODO Describe where controller tests live (test/controllers)
# TODO Describe how controller tests are named
# (test/controllers/route_controller_test.rb)
#
# A typical controller test looks like this:
#
#   require 'test/test_helper'
#   
#   # We are testing RouteController's actions
#   class RouteControllerTest < Test::Rails::ControllerTestCase
#     
#     fixtures :users, :routes, :points, :photos
#     
#     # Testing the delete method
#     def test_delete
#       @request.session[:username] = users(:herbert).username
#       
#       get :delete, :id => routes(:work).id
#       
#       # assert we got a 200
#       assert_success
#       
#       # assert that instance variables are correctly assigned
#       assert_assigned :action_title, "Deleting \"#{routes(:work).name}\""
#       assert_assigned :route, routes(:work)
#     end
#     
#     # ...
#     
#   end
#
# The chages in a controller test are much less drastic, but I'll go through
# them step by step again.
#
# All controller tests are a subclass of Test::Rails::ControllerTestCase.  The
# name of the subclass must match the controller this test depends upon.
# ControllerTestCase takes care of all the setup necessary for running the
# tests.
#
# Fixtures work just like they do in a functional test.
#
# The +test_delete+ method is named after the delete method in
# RouteController.  This also matches the test_delete test in RouteViewTest
# which is important for auditing your tests.
#
# @request, @response, flash, etc. are available to you just like in a
# Functional test.
#
# get/post/process are available to you just like in functional tests.
#
# +assert_assigned :route, routes(:work)+ asserts that the instance variable
# +@route+ on the RouteController is set to routes(:work).  assert_assigned is
# used by the auditing script to match up a controller's set instance
# variables with which instance variables a view test needs to work.
#
# = Auditing your tests
#
# Test::Rails adds a script that looks at your controller tests and your view
# tests and checks for places you use an instance variable on one side but
# forgot to check for it on the other.
#
# Here's a controller test that's missing an assert_assigned for @route:
#
#   class RouteControllerTest < Test::Rails::ControllerTestCase
#     def test_flickr_refresh
#       @request.session[:username] = users(:herbert).username
#       
#       get :flickr_refresh, :id => routes(:work).id
#       
#       assert_success
#       
#       assert_assigned :tz_name, 'Pacific Time (US & Canada)'
#     end
#   end
#
# And here's a view test with all of its instance variable assignments:
#
#   class RouteViewTest < Test::Rails::ViewTestCase
#     def test_flickr_refresh
#       assigns[:route] = routes(:work)
#       assigns[:tz_name] = 'Pacific Time (US & Canada)'
#       
#       render
#       
#       form_url = '/route/flickr_refetch'
#       assert_post_form form_url
#       assert_input form_url, :hidden, :id
#       assert_input form_url, :text, :flickr_user
#       assert_tag_in_form form_url, :tag => 'select', :attributes => {
#                            :name => 'tz_name' }
#       assert_tag_in_form form_url, :tag => 'option', :attributes => {
#                            :selected => true, :value => /Pacific/ },
#                          :content => /Pacific/
#       assert_submit form_url, 'Refresh!'
#     end
#   end
#
# As you can see there's an ivar assignment for +@loggedin_user+, +@route+ and
# +@tz_name+, but there are no checks for +@route+ in the controller test.
# rails_test_audit will examine your view and controller tests and tell you
# where your controller tests are missing assert_assigns:
#
#   $ rails_test_audit
#   require 'test/test_helper'
#   
#   class RouteControllerTest < Test::Rails::ControllerTestCase
#     
#     def test_flickr_refresh
#       assert_assigned :route, routes(:work)
#     end
#     
#   end
#
# So here rails_test_audit is telling me I should add an assertion for
# +@route+ to +test_flickr_refresh+, which I indeed forgot.
#
# = Changes to rake tasks
#
# TODO Describe how new tests are run rake test:views, rake test:controllers.
#
# When you add require 'test/rails/rake_tasks' to your Rakefile the following
# changes get made to the rake tasks:
#
# test:views and test:controllers targets get added so you can run just the
# view or controller tests.
#
# The "test" target runs tests in the following order: units, controllers,
# views, functionals, integration.
#
# The test target no longer runs all tests, it stops on the first failure.
# This way a failure in a unit test doesn't fill your screen with crap because
# the brokenness also affected your controllers and views.
#
# The stats target is updated to account for controller and view tests.

module Test::Rails; end

class Object # :nodoc:
  def self.path2class(klassname)
    klassname.split('::').inject(Object) { |k,n| k.const_get n }
  end
end

require 'test/rails/controller_test_case'
require 'test/rails/ivar_proxy'
require 'test/rails/view_test_case'

