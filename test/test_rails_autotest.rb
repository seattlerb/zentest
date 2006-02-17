require 'test_autotest'
require 'rails_autotest'

class TestRailsAutotest < TestAutotest

  def setup
    super
    @at = RailsAutotest.new
  end

  def test_map_file_names
    file_names = [
      './app/helpers/application_helper.rb',
      './test/fixtures/routes.yml',
      './test/unit/photo_test.rb',
      './app/models/photo.rb',
      './app/controllers/application.rb',
      './app/controllers/route_controller.rb',
      './app/views/layouts/default.rhtml',
      './app/views/route/index.rhtml',
      './app/helpers/route_helper.rb',
    ]

    expected = [
      # ApplicationHelper
      [[], ['test/functional/route_controller_test.rb']],
      # fixture
      [['test/unit/route_test.rb'],
       ['test/functional/route_controller_test.rb']],
      # test
      [['test/unit/photo_test.rb'], []],
      # model
      [['test/unit/photo_test.rb'], []],
      # ApplicationController
      [[], ['test/functional/dummy_controller_test.rb']],
      # controller
      [[], ['test/functional/route_controller_test.rb']],
      # layout
      [[], []],
      # view
      [[], ['test/functional/route_controller_test.rb']],
      # helper
      [[], ['test/functional/route_controller_test.rb']],
    ]

    Dir.chdir 'test/data/rails' do
      file_names.each_with_index do |name, i|
        assert_equal expected[i], @at.map_file_names([name]),
                     "test #{i}, #{name}"
      end
    end
  end

end

