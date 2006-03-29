require 'test_autotest'
require 'rails_autotest'

class TestRailsAutotest < TestAutotest

  def setup
    super

    @at = RailsAutotest.new

    @rails_tests_dir = 'test/data/rails'

    @rails_photo_file             = 'app/models/photo.rb'
    @rails_photo_test_file        = 'test/unit/photo_test.rb'
    @rails_unit_tests = [
                         'test/unit/flickr_photo_test.rb',
      @rails_photo_test_file,
                         'test/unit/photo_test.rb',
                         'test/unit/route_test.rb',
                        ]

    @rails_functional_tests = [
                               'test/functional/admin/themes_controller_test.rb',
                               'test/functional/dummy_controller_test.rb',
                               'test/functional/route_controller_test.rb',
                              ]

    @rails_all_tests = [@rails_unit_tests, @rails_functional_tests]
  end

  (instance_methods.sort - Object.instance_methods).each do |meth|
    undef_method meth if meth =~ /^test_failed_test_files/
  end

  def test_map_file_names
    # controllers
    util_add_map("./app/controllers/admin/themes_controller.rb",
                 [], ["test/functional/admin/themes_controller_test.rb"])
    util_add_map("./app/controllers/application.rb",
                 [], ["test/functional/dummy_controller_test.rb"])
    util_add_map("./app/controllers/route_controller.rb",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("./app/controllers/notest_controller.rb")

    # helpers
    util_add_map("./app/helpers/application_helper.rb",
                 [], ["test/functional/dummy_controller_test.rb",
                      "test/functional/route_controller_test.rb"])
    util_add_map("./app/helpers/route_helper.rb",
                 [], ["test/functional/route_controller_test.rb"])

    # model
    util_add_map("./app/models/route.rb",
                 ["test/unit/route_test.rb"], [])
    util_add_map("./app/models/notest.rb")

    # views
    util_add_map("./app/views/layouts/default.rhtml")
    util_add_map("./app/views/route/index.rhtml",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("./app/views/route/xml.rxml",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("./app/views/shared/notest.rhtml")

    # tests
    util_add_map("./test/fixtures/routes.yml",
                 ["test/unit/route_test.rb"],
                 ["test/functional/route_controller_test.rb"])
    util_add_map("./test/functional/admin/themes_controller_test.rb",
                 [], ["test/functional/admin/themes_controller_test.rb"])
    util_add_map("./test/functional/route_controller_test.rb",
                 [], ["test/functional/route_controller_test.rb"])

    util_add_map("./test/unit/photo_test.rb",
                 ["test/unit/photo_test.rb"], [])

    util_add_map("./test/test_helper.rb",
                 @rails_unit_tests, @rails_functional_tests )

    # global conf thingies
    util_add_map("./config/boot.rb",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("./config/database.yml",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("./config/environment.rb",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("./config/environments/test.rb",
                 @rails_unit_tests, @rails_functional_tests )
    util_add_map("./config/routes.rb",
                 [], @rails_functional_tests)

    # ignored crap
    util_add_map("./vendor/plugins/cartographer/lib/keys.rb")
    util_add_map("./Rakefile")

    @rails_all_tests.flatten.each do |t|
      @at.files[t] = Time.at(0)
    end

    util_test_map_file_names @rails_tests_dir
  end

end

