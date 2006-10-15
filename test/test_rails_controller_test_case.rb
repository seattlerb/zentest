require 'test/unit'
require 'test/zentest_assertions'

$TESTING_RTC = true

require 'test/rails'

class TRController < ApplicationController
end

class TestRailsControllerTestCase < Test::Rails::ControllerTestCase
  
  def setup
    @controller_class_name = 'TRController'
    super
  end

  def assigns
    { 'ivar' => 'value' }
  end

  def test_assert_assigned
    assert_assigned :ivar
    assert_assigned :ivar, 'value'

    assert_raise Test::Unit::AssertionFailedError do
      assert_assigned :no_ivar
    end

    assert_raise Test::Unit::AssertionFailedError do
      assert_assigned :ivar, 'bad_value'
    end
  end

  def test_deny_assigned
    deny_assigned :no_ivar

    assert_raise Test::Unit::AssertionFailedError do
      deny_assigned :ivar
    end
  end

end

