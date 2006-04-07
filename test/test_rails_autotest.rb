require 'test_autotest'
require 'rails_autotest'

class TestRailsAutotest < TestAutotest

  def setup
    super

    @at = RailsAutotest.new

    @rails_tests_dir = 'test/data/rails'

    @rails_unit_tests = ['test/unit/route_test.rb']

    @rails_controller_tests = [
                               'test/controllers/admin/themes_controller_test.rb',
                               'test/controllers/articles_controller_test.rb',
                               'test/controllers/dummy_controller_test.rb',
                               'test/controllers/route_controller_test.rb',
                              ]

    @rails_view_tests = [
                         'test/views/admin/themes_view_test.rb',
                         'test/views/articles_view_test.rb',
                         'test/views/layouts_view_test.rb',
                         'test/views/route_view_test.rb',
                        ]

    @rails_functional_tests = [
                               'test/functional/admin/themes_controller_test.rb',
                               'test/functional/articles_controller_test.rb',
                               'test/functional/dummy_controller_test.rb',
                               'test/functional/route_controller_test.rb',
                              ]

    # These files aren't put in @file_map, so add them to it
    @extra_files = [
                    'test/controllers/admin/themes_controller_test.rb',
                    'test/controllers/articles_controller_test.rb',
                    'test/controllers/dummy_controller_test.rb',
                    'test/views/admin/themes_view_test.rb',
                    'test/views/articles_view_test.rb',
                    'test/views/layouts_view_test.rb',
                    'test/functional/articles_controller_test.rb',
                    'test/functional/dummy_controller_test.rb',
                   ]
  end

  # Remove test_failed_test_files tests from RailsAutoTest because these
  # tests are regular-mode dependent.
  superclass.instance_methods.each do |meth|
    undef_method meth if meth =~ /^test_failed_test_files/
  end

  def test_map_file_names
    # util_add_map(sourcefile, unit_tests, controller_tests,
    #                          view_tests, functional_tsets)

    # controllers
    util_add_map("app/controllers/admin/themes_controller.rb",
                 [], ["test/controllers/admin/themes_controller_test.rb"],
                 [], ["test/functional/admin/themes_controller_test.rb"])

    util_add_map("app/controllers/application.rb",
                 [], ["test/controllers/dummy_controller_test.rb"],
                 [], ["test/functional/dummy_controller_test.rb"])

    util_add_map("app/controllers/route_controller.rb",
                 [], ["test/controllers/route_controller_test.rb"],
                 [], ["test/functional/route_controller_test.rb"])

    util_add_map("app/controllers/notest_controller.rb")

    # helpers
    util_add_map("app/helpers/application_helper.rb",
                 [], [], @rails_view_tests, @rails_functional_tests)

    util_add_map("app/helpers/route_helper.rb",
                 [], [], ["test/views/route_view_test.rb"],
                 ["test/functional/route_controller_test.rb"])

    # model
    util_add_map("app/models/route.rb",
                 ["test/unit/route_test.rb"], [], [], [])

    util_add_map("app/models/notest.rb")

    # views
    util_add_map("app/views/layouts/default.rhtml", [], [],
                 ["test/views/layouts_view_test.rb"], [])

    util_add_map("app/views/route/index.rhtml",
                 [], [], ["test/views/route_view_test.rb"],
                 ["test/functional/route_controller_test.rb"])

    util_add_map("app/views/route/xml.rxml",
                 [], [], ["test/views/route_view_test.rb"],
                 ["test/functional/route_controller_test.rb"])

    util_add_map("app/views/shared/notest.rhtml")

    util_add_map("app/views/articles/flag.rhtml",
                 [], [], ["test/views/articles_view_test.rb"],
                 ["test/functional/articles_controller_test.rb"])

    # tests
    util_add_map("test/fixtures/routes.yml",
                 ["test/unit/route_test.rb"],
                 ["test/controllers/route_controller_test.rb"],
                 ["test/views/route_view_test.rb"],
                 ["test/functional/route_controller_test.rb"])

    util_add_map("test/test_helper.rb",
                 @rails_unit_tests, @rails_controller_tests,
                 @rails_view_tests, @rails_functional_tests)

    util_add_map("test/unit/route_test.rb",
                 ["test/unit/route_test.rb"], [], [], [])

    util_add_map("test/controllers/route_controller_test.rb",
                 [], ["test/controllers/route_controller_test.rb"], [], [])

    util_add_map("test/views/route_view_test.rb",
                 [], [], ["test/views/route_view_test.rb"], [])

    util_add_map("test/functional/route_controller_test.rb",
                 [], [], [], ["test/functional/route_controller_test.rb"])

    util_add_map("test/functional/admin/themes_controller_test.rb",
                 [], [], [], ["test/functional/admin/themes_controller_test.rb"])

    # global conf thingies
    util_add_map("config/boot.rb",
                 @rails_unit_tests, @rails_controller_tests,
                 @rails_view_tests, @rails_functional_tests)

    util_add_map("config/database.yml",
                 @rails_unit_tests, @rails_controller_tests,
                 @rails_view_tests, @rails_functional_tests)

    util_add_map("config/environment.rb",
                 @rails_unit_tests, @rails_controller_tests,
                 @rails_view_tests, @rails_functional_tests)

    util_add_map("config/environments/test.rb",
                 @rails_unit_tests, @rails_controller_tests,
                 @rails_view_tests, @rails_functional_tests)

    util_add_map("config/routes.rb",
                 [], @rails_controller_tests, @rails_view_tests,
                 @rails_functional_tests)

    # ignored crap
    util_add_map("vendor/plugins/cartographer/lib/keys.rb")

    util_add_map("Rakefile")

    (@file_map.keys + @extra_files).each { |file| @at.files[file] = Time.at 0 }

    util_test_map_file_names @rails_tests_dir
  end

  def test_updated_files_rails
    expected = [
      "app/controllers/admin/theme_controller.rb",
      "app/controllers/route_controller.rb",
      "app/models/flickr_photo.rb",
      "app/models/route.rb",
      "app/views/route/index.rhtml",
      "config/environment.rb",
      "config/routes.rb",
      "test/controllers/route_controller_test.rb",
      "test/fixtures/routes.yml",
      "test/functional/admin/themes_controller_test.rb",
      "test/functional/dummy_controller_test.rb",
      "test/functional/route_controller_test.rb",
      "test/unit/flickr_photo_test.rb",
      "test/unit/photo_test.rb",
      "test/unit/route_test.rb",
      "test/views/route_view_test.rb",
    ]

    Dir.chdir @rails_tests_dir do
      assert_equal expected, @at.updated_files.sort
    end
  end

  def util_add_map(file, *tests)
    tests = [[], [], [], []] if tests.empty?

    super(file, *tests)
  end

end

