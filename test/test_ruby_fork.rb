$TESTING = true

require 'test/unit'
require 'test/zentest_assertions'
require 'ruby_fork'

class TestRubyFork < Test::Unit::TestCase

  def test_parse_client_args
    expected = util_make_settings
    settings = RubyFork.parse_client_args []
    assert_equal expected, settings
  end

  def test_parse_client_args_help
    util_capture do
      assert_raises SystemExit do
        RubyFork.parse_client_args ['-h']
      end

      assert_raises SystemExit do
        RubyFork.parse_client_args ['--help']
      end
    end
  end

  def test_parse_client_args_port
    expected = util_make_settings [], [], [], 5

    settings = RubyFork.parse_client_args ['-p', '5']
    assert_equal expected, settings

    settings = RubyFork.parse_client_args ['--port', '5']
    assert_equal expected, settings
  end

  def test_parse_server_args
    settings = RubyFork.parse_server_args []
    expected = util_make_settings nil, nil, nil, nil, false
    assert_equal expected, settings
  end

  def test_parse_server_args_daemonize
    expected = util_make_settings [], [], [], RubyFork::PORT, true

    settings = RubyFork.parse_server_args ['-d']
    assert_equal expected, settings

    settings = RubyFork.parse_server_args ['--daemonize']
    assert_equal expected, settings
  end

  def test_parse_server_args_execute
    expected = util_make_settings [], ['foo']

    settings = RubyFork.parse_server_args ['-e', 'foo']
    assert_equal expected, settings

    expected = util_make_settings [], ['foo', 'bar']

    settings = RubyFork.parse_server_args ['-e', 'foo', '-e', 'bar']
    assert_equal expected, settings
  end

  def test_parse_server_args_include
    expected = util_make_settings nil, nil, ['lib'], nil, false

    settings = RubyFork.parse_server_args ['-I', 'lib']
    assert_equal expected, settings

    expected = util_make_settings nil, nil, ['lib', 'test'], nil, false

    settings = RubyFork.parse_server_args ['-I', 'lib', '-I', 'test']
    assert_equal expected, settings

    expected = util_make_settings nil, nil, ['lib:test'], nil, false

    settings = RubyFork.parse_server_args ['-I', 'lib:test']
    assert_equal expected, settings
  end

  def test_parse_server_args_help
    util_capture do
      assert_raises SystemExit do
        RubyFork.parse_server_args ['-h']
      end

      assert_raises SystemExit do
        RubyFork.parse_server_args ['--help']
      end
    end
  end

  def test_parse_server_args_port
    expected = util_make_settings nil, nil, nil, 5, false

    settings = RubyFork.parse_server_args ['-p', '5']
    assert_equal expected, settings

    settings = RubyFork.parse_server_args ['--port', '5']
    assert_equal expected, settings
  end

  def test_parse_server_args_execute
    expected = util_make_settings ['zentest'], nil, nil, nil, false

    settings = RubyFork.parse_server_args ['-r', 'zentest']
    assert_equal expected, settings

    expected = util_make_settings ['zentest', 'unit_diff'], nil, nil, nil, false

    settings = RubyFork.parse_server_args ['-r', 'zentest', '-r', 'unit_diff']
    assert_equal expected, settings
  end

  def test_setup_environment_extra_paths
    load_path = $LOAD_PATH.dup

    RubyFork.setup_environment :extra_paths => ['no_such_dir'],
                               :requires => [], :code => []

    assert_equal 'no_such_dir', $LOAD_PATH.first
  ensure
    $LOAD_PATH.replace load_path
  end

  def test_setup_environment_extra_paths_with_colon
    load_path = $LOAD_PATH.dup

    RubyFork.setup_environment :extra_paths => ['no_such_dir:other_bad_dir'],
                               :requires => [], :code => []

    assert_equal 'other_bad_dir', $LOAD_PATH[0]
    assert_equal 'no_such_dir',   $LOAD_PATH[1]
  ensure
    $LOAD_PATH.replace load_path
  end

  def test_setup_environment_requires
    assert_raises LoadError do
      RubyFork.setup_environment :extra_paths => [],
                                 :requires => ['no_such_file'], :code => []
    end
  end

  def test_setup_environment_code
    RubyFork.setup_environment :extra_paths => [],
                               :requires => [], :code => ['$trf_env_code = 0']

    assert_equal 0, $trf_env_code
  end

  def util_make_settings(requires = nil, code = nil, extra_paths = nil,
                         port = nil, daemonize = nil)
    settings = {
      :requires => [],
      :code => [],
      :extra_paths => [],
      :port => RubyFork::PORT,
    }

    settings[:code] = code unless code.nil?
    settings[:daemonize] = daemonize unless daemonize.nil?
    settings[:extra_paths] = extra_paths unless extra_paths.nil?
    settings[:port] = port unless port.nil?
    settings[:requires] = requires unless requires.nil?

    return settings
  end

end

