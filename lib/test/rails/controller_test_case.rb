##
# ControllerTestCase allows controllers to be tested independent of their
# views.
#
# == Naming
#
# The test class must be named +ControllerNameControllerTest+, so if you're
# testing actions for the +RouteController+ you would name your test case
# +RouteControllerTest+.
#
# The test names should be +test_actionname_extra+ wher the actionname
# corresponds to the name of the controller action.  If you are testing an
# action named 'show' your test should be named +test_show+.  If your action
# behaves differently depending upon its arguments you can make the test name
# descriptive with extra arguments like +test_show_photos+ and
# +test_show_no_photos+.
#
# == Examples
#
#   class RouteControllerTest < Test::Rails::ControllerTestCase
#     
#     fixtures :users, :routes, :points, :photos
#     
#     def test_delete
#       # Set up our environment
#       @request.session[:username] = users(:herbert).username
#       
#       # perform the delet action
#       get :delete, :id => routes(:work).id
#       
#       # Assert we got a 200
#       assert_success
#       # Ensure that @action_title is set properly
#       assert_assigned :action_title, "Deleting \"#{routes(:work).name}\""
#       # Ensure that @route is set properly
#       assert_assigned :route, routes(:work)
#     end
#     
#   end
#
#--
# TODO: Make session transparent
# TODO: Get rid of assert_success and friends, deprecated in Rails
# TODO: Ensure that assert_tag doesn't work (maybe)

class Test::Rails::ControllerTestCase < Test::Unit::TestCase

  NOTHING = Object.new # :nodoc:

  def setup
    return if self.class.name =~ /TestCase$/
    klass_name = self.class.name.sub(/View/, 'Controller')
    klass_name =~ /\A(.*)Test\Z/
    raise "Can't find controller name in #{self.class}" unless $1
    controller_klass = Object.path2class $1
    controller_klass.send(:define_method, :rescue_action) { |e| raise e }
    @controller = controller_klass.new
    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new

    @deliveries = []
    ActionMailer::Base.deliveries = @deliveries
  end

  def test_stupid # :nodoc:
  end

  ##
  # Asserts that the assigns variable +ivar+ is assigned to +value+.  If
  # +value+ is omitted, asserts that assigns variable +ivar+ exists.

  def assert_assigned(ivar, value = NOTHING)
    ivar = ivar.to_s
    assert_includes assigns, ivar, "#{ivar.inspect} missing from assigns"
    assert_equal value, assigns[ivar] unless value.equal? NOTHING
  end

  ##
  # Asserts the response content type matches +type+.

  def assert_content_type(type, message = nil)
    assert_equal type, @response.headers['Content-Type'], message
  end

  ##
  # Asserts that a page gave a 500 Server Error response.

  def assert_error
    assert_response 500
  end

  ##
  # Asserts that +key+ of flash has +content+.  If +content+ is a Regexp, then
  # the assertion will fail if the Regexp does not match.
  #
  # controller:
  #   flash[:notice] = 'Please log in'
  #
  # test:
  #   assert_flash :notice, 'Please log in'

  def assert_flash(key, content)
    assert flash.include?(key), "#{key.inspect} missing from flash"
    case content
    when Regexp
      assert_match content, flash[key],
                   "Content of flash[#{key.inspect}] did not match"
    else
      assert_equal content, flash[key],
                   "Incorrect content in flash[#{key.inspect}]"
    end
  end

  ##
  # Asserts that a page gave a 403 Forbidden response.

  def assert_forbidden
    assert_response 403
  end

  ##
  # Asserts that a page gave a 404 Not Found response.

  def assert_not_found
    assert_response 404
  end

  ##
  # Asserts that the assigns variable +ivar+ is not assigned to +value+.  If
  # +value+ is not present, asserts that the assigns variable is not present.

  def deny_assigned(ivar, value = NOTHING)
    ivar = ivar.to_s
    if value.equal? NOTHING then
      deny_includes assigns, ivar
    else
      assert_includes assigns, ivar, "#{ivar.inspect} missing from assigns"
      deny_equal value, assigns[ivar]
    end
  end

end

module Test::Unit::Assertions

  def deny(boolean, message = nil)
    _wrap_assertion do
      assert_block(build_message(message, "<?> is not false or nil.", boolean)) { not boolean }
    end
  end

  alias deny_equal assert_not_equal

  def deny_empty(obj)
    assert_respond_to obj, :empty?
    assert_equal false, obj.empty?
  end

  def assert_includes(obj, item, message = nil)
    assert_respond_to obj, :include?
    assert_equal true, obj.include?(item), message
  end

  def deny_includes(obj, item, message = nil)
    assert_respond_to obj, :include?
    assert_equal false, obj.include?(item), message
  end

end

