require 'test_autotest'
require 'rails_autotest'

class TestRailsAutotest < TestAutotest

  def setup
    super

    # TODO: rename @a and make superclass tests less brittle
    @at = RailsAutotest.new # REFACTOR
    @at.files.clear
    @at.output = StringIO.new

    @a = @at

    @test_class = 'RouteTest'
    @test = 'test/unit/route_test.rb'
    @impl = 'app/models/route.rb'

    @rails_unit_tests = [@test]

    @rails_controller_tests = %w(test/controllers/admin/themes_controller_test.rb
                                 test/controllers/articles_controller_test.rb
                                 test/controllers/dummy_controller_test.rb
                                 test/controllers/route_controller_test.rb)

    @rails_view_tests = %w(test/views/admin/themes_view_test.rb
                           test/views/articles_view_test.rb
                           test/views/layouts_view_test.rb
                           test/views/route_view_test.rb)

    @rails_functional_tests = %w(test/functional/admin/themes_controller_test.rb
                                 test/functional/articles_controller_test.rb
                                 test/functional/dummy_controller_test.rb
                                 test/functional/route_controller_test.rb)

    # These files aren't put in @file_map, so add them to it
    @extra_files = %w(test/controllers/admin/themes_controller_test.rb
                      test/controllers/articles_controller_test.rb
                      test/controllers/dummy_controller_test.rb
                      test/functional/articles_controller_test.rb
                      test/functional/dummy_controller_test.rb
                      test/views/admin/themes_view_test.rb
                      test/views/articles_view_test.rb
                      test/views/layouts_view_test.rb)

    (@rails_unit_tests +
     @rails_controller_tests +
     @rails_view_tests +
     @rails_functional_tests +
     @extra_files).flatten.each_with_index do |path, t|
      @at.files[path] = Time.at(t+1)
    end
  end

  # REFACTOR
  def test_consolidate_failures_multiple_matches
    @test2 = 'test/unit/route_again_test.rb'
    @a.files[@test2] = Time.at(42)
    result = @a.consolidate_failures([['test_unmatched', @test_class]])
    expected = {"test/unit/route_test.rb"=>["test_unmatched"]}
    assert_equal expected, result
    assert_equal '', @a.output.string
  end

  def test_tests_for_file
    empty = []
    assert_equal empty, @at.tests_for_file('blah.rb')
    assert_equal empty, @at.tests_for_file('test_blah.rb')

    # controllers
    util_tests_for_file('app/controllers/admin/themes_controller.rb',
                        'test/controllers/admin/themes_controller_test.rb',
                        'test/functional/admin/themes_controller_test.rb')

    util_tests_for_file('app/controllers/application.rb',
                        'test/controllers/dummy_controller_test.rb',
                        'test/functional/dummy_controller_test.rb')

    util_tests_for_file('app/controllers/route_controller.rb',
                        'test/controllers/route_controller_test.rb',
                        'test/functional/route_controller_test.rb')

    util_tests_for_file('app/controllers/notest_controller.rb')

    # helpers
    util_tests_for_file('app/helpers/application_helper.rb',
                        @rails_view_tests + @rails_functional_tests)

    util_tests_for_file('app/helpers/route_helper.rb',
                        'test/views/route_view_test.rb',
                        'test/functional/route_controller_test.rb')

    # model
    util_tests_for_file('app/models/route.rb',
                        @test)

    util_tests_for_file('app/models/notest.rb')

    # views
    util_tests_for_file('app/views/layouts/default.rhtml',
                        'test/views/layouts_view_test.rb')

    util_tests_for_file('app/views/route/index.rhtml',
                        'test/views/route_view_test.rb',
                        'test/functional/route_controller_test.rb')

    util_tests_for_file('app/views/route/xml.rxml',
                        'test/views/route_view_test.rb',
                        'test/functional/route_controller_test.rb')

    util_tests_for_file('app/views/shared/notest.rhtml')

    util_tests_for_file('app/views/articles/flag.rhtml',
                        'test/views/articles_view_test.rb',
                        'test/functional/articles_controller_test.rb')

    # tests
    util_tests_for_file('test/fixtures/routes.yml',
                        @test,
                        'test/controllers/route_controller_test.rb',
                        'test/views/route_view_test.rb',
                        'test/functional/route_controller_test.rb')

    util_tests_for_file('test/test_helper.rb',
                        @rails_unit_tests, @rails_controller_tests,
                        @rails_view_tests, @rails_functional_tests)

    util_tests_for_file(@test, @test)

    util_tests_for_file('test/controllers/route_controller_test.rb',
                        'test/controllers/route_controller_test.rb')

    util_tests_for_file('test/views/route_view_test.rb',
                        'test/views/route_view_test.rb')

    util_tests_for_file('test/functional/route_controller_test.rb',
                        'test/functional/route_controller_test.rb')

    util_tests_for_file('test/functional/admin/themes_controller_test.rb',
                        'test/functional/admin/themes_controller_test.rb')

    # global conf thingies
    util_tests_for_file('config/boot.rb',
                        @rails_unit_tests, @rails_controller_tests,
                        @rails_view_tests, @rails_functional_tests)

    util_tests_for_file('config/database.yml',
                        @rails_unit_tests, @rails_controller_tests,
                        @rails_view_tests, @rails_functional_tests)

    util_tests_for_file('config/environment.rb',
                        @rails_unit_tests, @rails_controller_tests,
                        @rails_view_tests, @rails_functional_tests)

    util_tests_for_file('config/environments/test.rb',
                        @rails_unit_tests, @rails_controller_tests,
                        @rails_view_tests, @rails_functional_tests)

    util_tests_for_file('config/routes.rb',
                        @rails_controller_tests,
                        @rails_view_tests, @rails_functional_tests)

    # ignored crap
    util_tests_for_file('vendor/plugins/cartographer/lib/keys.rb')

    util_tests_for_file('Rakefile')
  end

  def util_tests_for_file(file, *expected)
    assert_equal(expected.flatten.sort.uniq,
                 @at.tests_for_file(file).sort.uniq, "tests for #{file}")
  end
end

