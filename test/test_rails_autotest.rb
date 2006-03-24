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

  def test_failed_test_files_updated
    failed_files = nil
    klass = 'RouteTest'
    tests = [@rails_route_test_file]

    Dir.chdir @rails_tests_dir do
      @at.updated? @rails_route_test_file
      util_touch @rails_route_test_file

      failed_files = @at.failed_test_files klass, tests
    end

    assert_equal [@rails_route_test_file], failed_files
  end

  def test_failed_test_files_updated_camelcase
    failed_files = nil
    klass = 'FlickrPhotoTest'
    tests = [@rails_flickr_photo_test_file]

    Dir.chdir @rails_tests_dir do
      @at.updated? @rails_flickr_photo_test_file
      util_touch @rails_flickr_photo_test_file

      failed_files = @at.failed_test_files klass, tests
    end

    assert_equal [@rails_flickr_photo_test_file], failed_files
  end

  def test_failed_test_files_updated_implementation
    failed_files = nil
    klass = 'RouteTest'
    tests = [@rails_route_test_file]

    Dir.chdir @rails_tests_dir do
      @at.updated? @rails_route_file
      util_touch @rails_route_file

      failed_files = @at.failed_test_files klass, tests
    end

    assert_equal [@rails_route_test_file], failed_files
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

