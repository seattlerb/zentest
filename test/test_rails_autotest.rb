require 'test_autotest'
require 'rails_autotest'

class TestRailsAutotest < TestAutotest

  def setup
    super

    @at = RailsAutotest.new

    @rails_tests_dir = 'test/data/rails'

    @rails_route_file             = 'app/models/route.rb'
    @rails_route_test_file        = 'test/unit/route_test.rb'
    @rails_flickr_photo_file      = 'app/models/flickr_photo.rb'
    @rails_flickr_photo_test_file = 'test/unit/flickr_photo_test.rb'

    @rails_route_controller_file      = 'app/controllers/route_controller.rb'
    @rails_route_controller_test_file = 'test/functional/route_controller_test.rb'

    @rails_unit_tests = [
      @rails_flickr_photo_test_file,
      @rails_route_test_file,
    ]

    @rails_functional_tests = [
      'test/functional/admin/themes_controller_test.rb',
      'test/functional/dummy_controller_test.rb',
      @rails_route_controller_test_file,
    ]

    @rails_all_tests = [@rails_unit_tests, @rails_functional_tests]
  end

  (instance_methods.sort - Object.instance_methods).each do |meth|
    undef_method meth if meth =~ /^test_failed_test_files/
  end

  def util_add_map(file, unit_tests = [], functional_tests = [])
    @file_map[file] = [ unit_tests, functional_tests ]
  end

  def test_map_file_names
    @file_map = {}

    @rails_all_tests.flatten.each do |t|
      @at.files[t] = Time.at(0)
    end

    # controllers
    util_add_map("./app/controllers/admin/themes_controller.rb",
                 [], ["test/functional/admin/themes_controller_test.rb"])
    util_add_map("./app/controllers/application.rb",
                 [], ["test/functional/dummy_controller_test.rb"])
    util_add_map("./app/controllers/route_controller.rb",
                 [], ["test/functional/route_controller_test.rb"])

    # helpers
    util_add_map("./app/helpers/application_helper.rb",
                 [], ["test/functional/dummy_controller_test.rb",
                      "test/functional/route_controller_test.rb"])
    util_add_map("./app/helpers/route_helper.rb",
                 [], ["test/functional/route_controller_test.rb"])

    # model
    util_add_map("./app/models/photo.rb",
                 ["test/unit/photo_test.rb"], [])

    # views
    util_add_map("./app/views/layouts/default.rhtml")
    util_add_map("./app/views/route/index.rhtml",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("./app/views/route/xml.rxml",
                 [], ["test/functional/route_controller_test.rb"])
    util_add_map("./app/views/shared/crap.rhtml")

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

    Dir.chdir @rails_tests_dir do
      @file_map.each do |name, expected|
        assert_equal expected, @at.map_file_names([name.dup]), "test #{name}"
      end
    end
  end

end

