$TESTING = true

require 'stringio'
require 'test/unit'

require 'autotest'

Dir.chdir File.join(File.dirname(__FILE__), "..")

class Autotest

  attr_accessor :system_responses
  attr_reader :files

  def system(cmd)
    @system_responses ||= []
    raise 'Out of system responses' if @system_responses.empty?
    return @system_responses.shift
  end

  attr_accessor :backtick_responses

  def `(cmd)                            # ` appeases emacs
    @backtick_responses ||= []
    raise 'Out of backtick responses' if @backtick_responses.empty?
    return @backtick_responses.shift
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

    @all_files = [ @blah_file, @photo_file, @photo_test_file, @route_test_file, @user_test_file, @camelcase_test_file ]

    Dir.chdir @normal_tests_dir do
      util_touch @photo_file, (Time.now - 60)
      util_touch @photo_test_file, (Time.now - 60)
      util_touch @camelcase_test_file, (Time.now - 60)
    end

    @at = Autotest.new
  end

  def test_consolidate_failures
    failed = [
      %w[test_a TestOne],
      %w[test_b TestOne],
      %w[test_c TestOne],
      %w[test_d TestTwo],
    ]

    expected = [
      ["'/^(test_a|test_b|test_c)/'", /one/],
      ["'/^(test_d)/'", /two/],
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
    @at.files['test/test_autotest.rb'] = Time.at 1
    @at.files['lib/autotest.rb'] = Time.at 1

    file_names = [
                  'lib/untested.rb',
                  'lib/autotest.rb',
                  'lib/auto_test.rb',
                  'test/test_autotest.rb',
                 ]

    expected = [
                [[]],
                [['test/test_autotest.rb']],
                [['test/test_autotest.rb']],
                [['test/test_autotest.rb']],
               ]

    file_names.each_with_index do |name, i|
      assert_equal expected[i], @at.map_file_names([name]), "test #{i}, #{name}"
    end
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
      assert_equal "+ ruby -Ilib:test #{@photo_test_file} -n test_route | unit_diff -u", out.shift

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

