##
# FunctionalTestCase is an abstract class that sets up a controller instance
# for its subclasses.

class Test::Rails::FunctionalTestCase < Test::Unit::TestCase

  ##
  # Sets up instance variables to allow tests depending on a controller work.
  #
  # setup uses the instance variable @controller_class_name to determine which
  # controller class to instantiate.
  #
  # setup also instantiates a new @request and @response object.

  def setup
    return if self.class.name =~ /TestCase$/

    @controller_class = Object.path2class @controller_class_name
    raise "Can't determine controller class for #{self.class}" if @controller_class.nil?

    @controller = @controller_class.new

    @request = ActionController::TestRequest.new
    @response = ActionController::TestResponse.new
  end

  def test_stupid # :nodoc:
  end

end

