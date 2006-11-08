require 'test/unit'
require 'test/zentest_assertions'

$TESTING_RTC = true

begin
  require 'test/rails'
rescue LoadError, NameError
  $TESTING_RTC = false
end

class View; end

class TestRailsViewTestCase < Test::Rails::ViewTestCase

  def setup
    # override
    @request = Object.new
    def @request.body; @body; end
    def @request.body=(body); @body = body; end

    @assert_tag = []
  end

  def test_assert_text_area
    @request.body = '
<form action="/post/save">
<textarea id="post_body" name="post[body]">
OMG he like hates me and he\'s like going out with this total skank!~ oh noes!!~
</textarea>
</form>
'

    assert_text_area '/post/save', 'post[body]'

    expected = {
      :tag => 'form', :attributes => { :action => '/post/save' },
        :descendant => {
          :tag => 'textarea', :attributes => { :name => 'post[body]' } } }

    assert_equal expected, @assert_tag.first

    assert_text_area '/post/save', 'post[body]',
                     "OMG he like hates me and he's like going out with this total skank!~ oh noes!!~"

    expected = {
      :tag => 'form', :attributes => { :action => '/post/save' },
        :descendant => {
          :tag => 'textarea', :attributes => { :name => 'post[body]' },
            :content => 
              "OMG he like hates me and he's like going out with this total skank!~ oh noes!!~" } }

    assert_equal expected, @assert_tag.last
  end

  def assert_tag(arg)
    @assert_tag << arg
  end

end if $TESTING_RTC

