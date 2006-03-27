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
  end

  (instance_methods.sort - Object.instance_methods).each do |meth|
    undef_method meth if meth =~ /^test_failed_test_files/
  end

  def test_map_file_names
    file_names = [
      './app/helpers/application_helper.rb',

      './test/fixtures/routes.yml',

      './app/models/photo.rb',
      './test/unit/photo_test.rb',

      './app/controllers/application.rb',

      './app/controllers/route_controller.rb',
      './test/functional/route_controller_test.rb',

      './app/views/layouts/default.rhtml',

      './app/views/route/index.rhtml',

      './app/helpers/route_helper.rb',

      './config/routes.rb',

      './app/controllers/admin/themes_controller.rb',
      './test/functional/admin/themes_controller_test.rb',
    ]

    expected = [
      # ApplicationHelper
      [[], ['test/functional/dummy_controller_test.rb',
            'test/functional/route_controller_test.rb']],

      # Fixture
      [['test/unit/route_test.rb'],
       ['test/functional/route_controller_test.rb']],

      # Model
      [['test/unit/photo_test.rb'], []],

      # Model test
      [['test/unit/photo_test.rb'], []],

      # ApplicationController
      [[], ['test/functional/dummy_controller_test.rb']],

      # Controller
      [[], ['test/functional/route_controller_test.rb']],

      # Controller test
      [[], ['test/functional/route_controller_test.rb']],

      # Layout
      [[], []],

      # View
      [[], ['test/functional/route_controller_test.rb']],

      # Helper
      [[], ['test/functional/route_controller_test.rb']],

      # config/routes.rb
      [[], ['test/functional/admin/themes_controller_test.rb',
            'test/functional/dummy_controller_test.rb',
            'test/functional/route_controller_test.rb']],

      # Nested controller
      [[], ['test/functional/admin/themes_controller_test.rb']],

      # Nested controller test
      [[], ['test/functional/admin/themes_controller_test.rb']],
    ]

    Dir.chdir @rails_tests_dir do
      file_names.each_with_index do |name, i|
        assert_equal expected[i], @at.map_file_names([name]),
                     "test #{i}, #{name}"
      end
    end
  end

end

