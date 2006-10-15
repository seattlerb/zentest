require 'test/unit'
require 'test/zentest_assertions'
require 'test/rails'

begin
  module TRHelper
    def tr_helper; end
  end
  class TRHelperTest < Test::Rails::HelperTestCase; end
rescue RuntimeError
end

begin
  module Widgets; end
  module Widgets::SomeHelper
    def widgets_some_helper; end
  end
  class Widgets::SomeHelperTest < Test::Rails::HelperTestCase; end
rescue RuntimeError
end

class TestRailsHelperTestCase < Test::Unit::TestCase

  def test_self_inherited
    assert defined? TRHelperTest

    assert_includes 'tr_helper', TRHelperTest.instance_methods
  end

  def test_self_inherited_namespaced
    assert defined? Widgets
    assert defined? Widgets::SomeHelperTest

    assert_includes 'widgets_some_helper',
                    Widgets::SomeHelperTest.instance_methods
  end

end

