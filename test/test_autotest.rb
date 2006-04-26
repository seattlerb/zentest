$TESTING = true

require 'stringio'
require 'test/unit'
require 'test/zentest_assertions'

require 'autotest'

Dir.chdir File.join(File.dirname(__FILE__), "..")

class Autotest

  attr_reader :files

  attr_accessor :system_responses, :system_cmds

  def system(cmd)
    @system_cmds << cmd
    raise 'Out of system responses' if @system_responses.empty?
    return @system_responses.shift
  end

  attr_accessor :backtick_responses, :backtick_cmds

  def `(cmd)                            # ` appeases emacs
    @backtick_cmds << cmd
    raise 'Out of backtick responses' if @backtick_responses.empty?
    return @backtick_responses.shift
  end

  def test_initialize
    @backtick_cmds = []
    @system_cmds = []
    @backtick_responses = []
    @system_responses = []
  end

end

class TestAutotest < Test::Unit::TestCase

  def setup
    @normal_tests_dir = 'test/data/normal'

    @blah_file           = 'lib/blah.rb'
    @photo_file          = 'lib/photo.rb'
    @photo_test_file     = 'test/test_photo.rb'
    @route_test_file     = 'test/test_route.rb'
    @user_test_file      = 'test/test_user.rb'
    @camelcase_test_file = 'test/test_camelcase.rb'

    @file_map = {}

    @all_files = [ @blah_file, @photo_file, @photo_test_file, @route_test_file, @user_test_file, @camelcase_test_file ]

    Dir.chdir @normal_tests_dir do
      util_touch @photo_file, (Time.now - 60)
      util_touch @photo_test_file, (Time.now - 60)
      util_touch @camelcase_test_file, (Time.now - 60)
    end

    @at = Autotest.new
    @at.test_initialize
  end

  def test_consolidate_failures
    failed = [
      %w[test_a TestOne],
      %w[test_b TestOne],
      %w[test_c TestOne],
      %w[test_d TestTwo],
    ]

    expected = [
      ['"/^(test_a|test_b|test_c)$/"', /one/],
      ['"/^(test_d)$/"', /two/],
    ]

    assert_equal expected,
                 @at.consolidate_failures(failed).sort_by { |f,k| k.source }
  end

  # 0 files update, 0 run
  def test_failed_test_files_no_updates
    tests = [@user_test_file, @photo_test_file]
    updated_files = []

    failed_files = @at.failed_test_files(/photo/, tests, updated_files)

    assert_equal [], failed_files
  end

  # 1 test changes, 1 test runs
  def test_failed_test_files_test_updated
    tests = [@user_test_file, @photo_test_file]
    updated_files = [@photo_test_file]

    failed_files = @at.failed_test_files(/photo/, tests, updated_files)

    assert_equal [@photo_test_file], failed_files
  end

  # non-matching test class changed, 0 test runs
  def test_failed_test_files_unrelated_test_updated
    tests = [@user_test_file, @photo_test_file]
    updated_files = [@user_test_file]

    failed_files = @at.failed_test_files(/photo/, tests, updated_files)

    assert_equal [], failed_files
  end

  # tests handling of camelcase test matching
  def test_failed_test_files_camelcase_updated
    tests = [@camelcase_test_file]
    updated_files = [@camelcase_test_file]

    failed_files = @at.failed_test_files(/camel_?case/, tests, updated_files)

    assert_equal [@camelcase_test_file], failed_files
  end

  # running back to back with different classes should give updates for each
  # class.
  def test_failed_test_files_implementation_updated_both
    tests = [@photo_test_file, @user_test_file]
    updated_files = [@blah_file]

    failed_files = @at.failed_test_files(/photo/, tests, updated_files)

    assert_equal [@photo_test_file], failed_files

    failed_files = @at.failed_test_files(/user/, tests, updated_files)

    assert_equal [@user_test_file], failed_files
  end

  # "general" file changes, run all failures + mapped file
  def test_failed_test_files_implementation_updated
    tests = [@user_test_file, @photo_test_file]
    updated_files = [@blah_file]

    failed_files = @at.failed_test_files(/photo/, tests, updated_files)

    assert_equal [@photo_test_file], failed_files
  end

  def test_failure_report
    @at.files['test/test_one.rb'] = Time.at 0
    @at.files['test/test_two.rb'] = Time.at 0

    failures = [
      ["'/^(test_a|test_b|test_c)/'", /one/],
      ["'/^(test_d)/'", /two/],
    ]

    expected = "# failures remain in 2 files:
#  test/test_one.rb:
#    test_a
#    test_b
#    test_c
#  test/test_two.rb:
#    test_d"

    assert_equal expected, @at.failure_report(failures)
  end

  def test_map_file_names
    util_add_map('lib/untested.rb', [])
    util_add_map('lib/autotest.rb', ['test/test_autotest.rb'])
    util_add_map('lib/auto_test.rb', ['test/test_autotest.rb'])
    util_add_map('test/test_autotest.rb', ['test/test_autotest.rb'])

    @file_map.keys.each { |file| @at.files[file] = Time.at 0 }

    util_test_map_file_names @normal_tests_dir
  end

  def test_retest_failed_modified
    Dir.chdir @normal_tests_dir do
      @all_files.each do |f| @at.updated? f; end

      failed = [['test_route', /photo/]]
      tests = [@photo_test_file]

      @at.backtick_responses = ['1 tests, 1 assertions, 0 failures, 0 errors']

      util_touch @photo_test_file

      out, err = util_capture do
        @at.retest_failed failed, tests
      end

      out = out.split $/

      assert_equal "# Waiting for changes", out.shift
      assert_equal "# Rerunning failures: #{@photo_test_file}", out.shift
      assert_equal "+ #{@at.ruby} -Ilib:test #{@photo_test_file} -n test_route | unit_diff -u", out.shift

      assert_equal true, @at.backtick_responses.empty?
    end
  end

  def test_reset_times
    Dir.chdir @normal_tests_dir do
      @at.updated?(@photo_test_file)

      assert_equal false, @at.updated?(@photo_test_file), 'In @files'
      time = @at.files[@photo_test_file]

      @at.reset_times

      assert_not_equal time, @at.files[@photo_test_file]
      assert_equal true, @at.updated?(@photo_test_file), 'Time reset to 0'
    end
  end

  def test_ruby
    this_ruby = File.join(Config::CONFIG['bindir'],
                          Config::CONFIG['ruby_install_name'])
    assert_equal this_ruby, @at.ruby
  end

  def test_updated_eh
    Dir.chdir @normal_tests_dir do
      assert_equal true,  @at.updated?(@photo_test_file), 'Not in @files'
      assert_equal false, @at.updated?(@photo_test_file), 'In @files'
      @at.files[@photo_test_file] = Time.at 1
      util_touch @photo_test_file
      assert_equal true,  @at.updated?(@photo_test_file), 'Touched'
    end
  end

  def test_updated_files
    Dir.chdir @normal_tests_dir do
      @at.updated_files

      expected = Hash[*@all_files.map { |f| [f, File.stat(f).mtime] }.flatten]

      assert_equal expected, @at.files

      util_touch @photo_test_file

      assert_not_equal expected['test/test_photo.rb'], @at.files
    end
  end

  def test_vcs_update_no_vcs
    $vcstime = 600
    $vcs = nil
    @at.vcs_update
    assert_empty @at.system_cmds
  end

  def test_vcs_update_cvs
    @at.system_responses << ''
    $vcstime = -1
    $vcs = 'cvs'
    @at.vcs_update
    assert_equal ['cvs up'], @at.system_cmds
  end

  def test_vcs_update_p4
    @at.system_responses << "File(s) up-to-date.\n"
    $vcstime = -1
    $vcs = 'p4'
    @at.vcs_update
    assert_equal ['p4 sync'], @at.system_cmds
  end

  def test_vcs_update_svn
    @at.system_responses << ''
    $vcstime = -1
    $vcs = 'svn'
    @at.vcs_update
    assert_equal ['svn up'], @at.system_cmds
  end

  def util_add_map(file, *tests)
    @file_map[file] = tests
  end

  def util_test_map_file_names(dir)
    Dir.chdir dir do
      @file_map.each do |name, expected|
        assert_equal expected, @at.map_file_names([name.dup]), "test #{name}"
      end
    end
  end

  def util_capture
    old_stdout = $stdout
    old_stderr = $stderr
    out = StringIO.new
    err = StringIO.new
    $stdout = out
    $stderr = err
    yield
    return out.string, err.string
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  def util_touch(file, t = Time.now)
    File.utime(t, t, file)
  end

end

