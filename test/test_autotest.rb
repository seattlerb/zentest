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
    @photo_file          = 'test/data/normal/lib/photo.rb'
    @photo_test_file     = 'test/data/normal/test/test_photo.rb'
    @route_test_file     = 'test/data/normal/test/test_route.rb'
    @user_test_file      = 'test/data/normal/test/test_user.rb'
    @camelcase_test_file = 'test/data/normal/test/test_camelcase.rb'

    util_touch @photo_file, (Time.now - 60)
    util_touch @photo_test_file, (Time.now - 60)
    util_touch @camelcase_test_file, (Time.now - 60)

    @at = Autotest.new
  end

  def test_failed_test_files_not_updated
    klass = 'TestPhoto'
    tests = [@user_test_file, @photo_test_file]

    @at.updated? @photo_test_file

    failed_files = @at.failed_test_files klass, tests

    assert_equal [], failed_files
  end

  def test_failed_test_files_updated
    klass = 'TestPhoto'
    tests = [@user_test_file, @photo_test_file]

    @at.updated? @photo_test_file
    util_touch @photo_test_file

    failed_files = @at.failed_test_files klass, tests

    assert_equal [@photo_test_file], failed_files
  end

  def test_failed_test_files_updated_camelcase
    klass = 'TestCamelCase'
    tests = [@camelcase_test_file]

    @at.updated? @camelcase_test_file
    util_touch @camelcase_test_file

    failed_files = @at.failed_test_files klass, tests

    assert_equal [@camelcase_test_file], failed_files
  end

  def test_failed_test_files_updated_implementation
    klass = 'TestPhoto'
    tests = [@user_test_file, @photo_test_file]

    @at.updated? @photo_file
    util_touch @photo_file

    failed_files = @at.failed_test_files klass, tests

    assert_equal [@photo_test_file], failed_files
  end

  def test_map_file_names
    @at.files['test/test_autotest.rb'] = Time.at 1
    @at.files['lib/autotest.rb'] = Time.at 1

    file_names = [
      'lib/autotest.rb',
      'lib/auto_test.rb',
      'test/test_autotest.rb',
    ]

    expected = [
      [['test/test_autotest.rb']],
      [['test/test_autotest.rb']],
      [['test/test_autotest.rb']],
    ]

    file_names.each_with_index do |name, i|
      assert_equal expected[i], @at.map_file_names([name]), "test #{i}, #{name}"
    end
  end

  def test_retest_failed_modified
    failed = [['test_route', 'TestPhoto']]
    tests = [@photo_test_file]

    @at.system_responses = [true]

    util_touch @photo_test_file

    out, err = util_capture do
      @at.retest_failed failed, tests
    end

    out = out.split $/

    assert_equal "# Rerunning failures: #{@photo_test_file}", out.shift
    assert_equal "+ ruby -Ilib:test -S testrb -n test_route #{@photo_test_file} | unit_diff -u", out.shift

    assert_equal true, @at.system_responses.empty?
  end

  def test_reset_times
    @at.updated?(@photo_test_file)
    assert_equal false, @at.updated?(@photo_test_file), 'In @files'
    time = @at.files[@photo_test_file]
    @at.reset_times
    assert_not_equal time, @at.files[@photo_test_file]
    assert_equal true, @at.updated?(@photo_test_file), 'Time reset to 0'
  end

  def test_updated_eh
    assert_equal true,  @at.updated?(@photo_test_file), 'Not in @files'
    assert_equal false, @at.updated?(@photo_test_file), 'In @files'
    @at.files[@photo_test_file] = Time.at 1
    util_touch @photo_test_file
    assert_equal true,  @at.updated?(@photo_test_file), 'Touched'
  end

  def test_updated_files
    Dir.chdir 'test/data/normal' do
      @at.updated_files
    end

    expected = {
      'lib/photo.rb'           => File.stat(@photo_file).mtime,
      'test/test_photo.rb'     => File.stat(@photo_test_file).mtime,
      'test/test_route.rb'     => File.stat(@route_test_file).mtime,
      'test/test_user.rb'      => File.stat(@user_test_file).mtime,
      'test/test_camelcase.rb' => File.stat(@camelcase_test_file).mtime,
    }

    assert_equal expected, @at.files

    util_touch @photo_test_file

    assert_not_equal expected['test_photo.rb'], @at.files
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

