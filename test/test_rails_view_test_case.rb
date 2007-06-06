require 'test/unit'
require 'test/zentest_assertions'

$TESTING_RTC = true

module Rails
  module VERSION
    STRING = '99.99.99'
  end
end

begin
  require 'test/rails'
rescue LoadError, NameError
  $TESTING_RTC = false
end

class TestRailsViewTestCase < Test::Rails::ViewTestCase

  def setup
    @assert_tag = []
    @assert_no_tag = []
  end

  def test_assert_field
    assert_field '/game/save', :text, :game, :amount

    assert_equal 2, @assert_tag.length

    expected = {
      :tag => 'form',
      :attributes => { :action => '/game/save' },
      :descendant => {
        :tag => 'input', :attributes => {
          :type => 'text', :name => 'game[amount]'
        }
      }
    }

    assert_equal expected, @assert_tag.first

    expected = {
      :tag => 'form',
      :attributes => { :action => '/game/save' },
      :descendant => {
        :tag => 'label', :attributes => {
          :for => 'game_amount'
        }
      }
    }

    assert_equal expected, @assert_tag.last
  end

  def test_assert_input
    assert_input '/game/save', :text, 'game[amount]'

    expected = {
      :tag => "form",
      :attributes => { :action => "/game/save" },
      :descendant => { :tag => "input",
        :attributes => { :type => 'text', :name => 'game[amount]' }
      },
    }
    
    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_label
    assert_label '/game/save', 'game_amount'

    expected = {
      :tag => "form",
      :attributes => { :action => "/game/save" },
      :descendant => { :tag => "label",
        :attributes => { :for => 'game_amount' }
      },
    }
    
    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_links_to
    assert_links_to '/game/show/1', 'hi'

    expected = {
      :tag => 'a',
      :attributes => { :href => '/game/show/1' },
      :content => 'hi'
    }

    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_multipart_form
    assert_multipart_form '/game/save'

    expected = {
      :tag => 'form',
      :attributes => { 
        :method => 'post', :action => '/game/save',
        :enctype => 'multipart/form-data'
      }
    }

    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_post_form
    assert_post_form '/game/save'

    expected = {
      :tag => 'form',
      :attributes => { 
        :method => 'post', :action => '/game/save'
      }
    }

    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_select_tag
    assert_select_tag '/game/save', :game, :location_id,
                      'Ballet' => 1, 'Guaymas' => 2

    assert_equal 2, @assert_tag.length

    expected = {
      :tag => "form",
      :attributes => { :action => "/game/save" },
      :descendant => {
        :child => {
          :tag => "option", :content => "Guaymas",
          :attributes => { :value => 2 }
        },
        :tag => "select",
        :attributes => { :name => "game[location_id]" }
      },
    }

    assert_equal expected, @assert_tag.shift

    expected = {
      :tag => "form",
      :attributes => { :action => "/game/save" },
      :descendant => {
        :child => {
          :tag => "option", :content => "Ballet",
          :attributes => { :value => 1 }
        },
        :tag => "select",
        :attributes => { :name => "game[location_id]" }
      },
    }

    assert_equal expected, @assert_tag.shift
  end

  def test_assert_submit
    assert_submit '/game/save', 'Save!'

    expected = {
      :tag => "form",
      :attributes => { :action => "/game/save" },
      :descendant => { :tag => "input",
        :attributes => { :type => 'submit', :value => 'Save!' }
      },
    }
    
    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_tag_in_form
    assert_tag_in_form '/game/save', :tag => 'input'

    expected = {
      :tag => "form",
      :attributes => { :action => "/game/save" },
      :descendant => { :tag => "input" },
    }
    
    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first
  end

  def test_assert_text_area
    assert_text_area '/post/save', 'post[body]'

    expected = {
      :tag => 'form', :attributes => { :action => '/post/save' },
        :descendant => {
          :tag => 'textarea', :attributes => { :name => 'post[body]' } } }

    assert_equal 1, @assert_tag.length
    assert_equal expected, @assert_tag.first

    assert_text_area '/post/save', 'post[body]',
                     "OMG he like hates me and he's like going out with this total skank!~ oh noes!!~"

    assert_equal 2, @assert_tag.length

    expected = {
      :tag => 'form',
      :attributes => { :action => '/post/save' },
      :descendant => {
        :tag => 'textarea', :attributes => { :name => 'post[body]' },
      }
    }

    assert_equal expected, @assert_tag.first

    expected = {
      :tag => 'form', :attributes => { :action => '/post/save' },
        :descendant => {
          :tag => 'textarea', :attributes => { :name => 'post[body]' },
            :content => 
              "OMG he like hates me and he's like going out with this total skank!~ oh noes!!~" } }

    assert_equal expected, @assert_tag.last
  end

  def test_deny_links_to
    deny_links_to '/game/show/1', 'hi'

    expected = {
      :tag => 'a',
      :attributes => { :href => '/game/show/1' },
      :content => 'hi'
    }

    assert_equal 1, @assert_no_tag.length
    assert_equal expected, @assert_no_tag.first
  end

  def assert_tag(arg)
    @assert_tag << arg
  end

  def assert_no_tag(arg)
    @assert_no_tag << arg
  end

end if $TESTING_RTC

