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

    assert_includes TRHelperTest.instance_methods, 'tr_helper'
  end

  def test_self_inherited_namespaced
    assert defined? Widgets
    assert defined? Widgets::SomeHelperTest

    assert_includes Widgets::SomeHelperTest.instance_methods,
                    'widgets_some_helper'
  end

end

