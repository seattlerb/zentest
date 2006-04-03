require 'test_autotest'
require 'rails_autotest'

class TestRailsAutotest < TestAutotest

  def setup
    super

    @at = RailsAutotest.new

    @rails_tests_dir = 'test/data/rails'

    @rails_unit_tests = ['test/unit/route_test.rb']

    @rails_functional_tests = [
                               'test/functional/admin/themes_controller_test.rb',
                               'test/functional/articles_controller_test.rb',
                               'test/functional/dummy_controller_test.rb',
                               'test/functional/route_controller_test.rb',
                              ]

    # These files aren't put in @file_map, so add them to it
    @extra_files = [
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
    # controllers
    # controllers
    util_add_map("app/controllers/admin/themes_controller.rb",
                 [], ["test/functional/admin/themes_controller_test.rb"])
    util_add_map("app/controllers/application.rb",
                 [], ["test/functional/dummy_controller_test.rb"])
    util_add_map("app/controllers/route_controller.rb",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("app/controllers/notest_controller.rb")

    # helpers
    util_add_map("app/helpers/application_helper.rb",
                 [], @rails_functional_tests)
    util_add_map("app/helpers/route_helper.rb",
                 [], ["test/functional/route_controller_test.rb"])

    # model
    util_add_map("app/models/route.rb",
                 ["test/unit/route_test.rb"], [])
    util_add_map("app/models/notest.rb")

    # views
    util_add_map("app/views/layouts/default.rhtml")
    util_add_map("app/views/route/index.rhtml",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("app/views/route/xml.rxml",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("app/views/shared/notest.rhtml")
    util_add_map("app/views/articles/flag.rhtml",
                 [], ["test/functional/articles_controller_test.rb"])

    # tests
    util_add_map("test/fixtures/routes.yml",
                 ["test/unit/route_test.rb"],
                 ["test/functional/route_controller_test.rb"])
    util_add_map("test/functional/admin/themes_controller_test.rb",
                 [], ["test/functional/admin/themes_controller_test.rb"])
    util_add_map("test/functional/route_controller_test.rb",
                 [], ["test/functional/route_controller_test.rb"])

    util_add_map("test/unit/route_test.rb",
                 ["test/unit/route_test.rb"], [])

    util_add_map("test/test_helper.rb",
                 @rails_unit_tests, @rails_functional_tests )

    # global conf thingies
    util_add_map("config/boot.rb",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("config/database.yml",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("config/environment.rb",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("config/environments/test.rb",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("config/routes.rb",
                 [], @rails_functional_tests)

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
      "test/fixtures/routes.yml",
      "test/functional/admin/themes_controller_test.rb",
      "test/functional/dummy_controller_test.rb",
      "test/functional/route_controller_test.rb",
      "test/unit/flickr_photo_test.rb",
      "test/unit/photo_test.rb",
      "test/unit/route_test.rb",
    ]

    Dir.chdir @rails_tests_dir do
      assert_equal expected, @at.updated_files.sort
    end
  end

end

