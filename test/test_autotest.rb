$TESTING = true

require 'stringio'
require 'test/unit'

require 'autotest'

class Autotest

  attr_accessor :system_responses
  attr_reader :files

  def system(cmd)
    @system_responses ||= []
    raise 'Out of system responses' if @system_responses.empty?
    return @system_responses.shift
  end

  attr_accessor :backtick_responses

  def `(cmd)
    @backtick_responses ||= []
    raise 'Out of backtick responses' if @backtick_responses.empty?
    return @backtick_responses.shift
  end

end

class TestAutotest < Test::Unit::TestCase

  def setup
    @photo_test_file = 'test/data/plain/photo_test.rb'
    @route_test_file = 'test/data/plain/route_test.rb'
    @user_test_file = 'test/data/plain/user_test.rb'

    util_touch @photo_test_file, (Time.now - 60)
    @at = Autotest.new
  end

  def test_failed_test_files_not_updated
    klass = 'PhotoTest'
    tests = [@user_test_file, @photo_test_file]

    @at.updated? @photo_test_file

    failed_files = @at.failed_test_files klass, tests

    assert_equal [], failed_files
  end

  def test_failed_test_files_updated
    klass = 'PhotoTest'
    tests = [@user_test_file, @photo_test_file]

    @at.updated? @photo_test_file
    util_touch @photo_test_file

    failed_files = @at.failed_test_files klass, tests

    assert_equal [@photo_test_file], failed_files
  end

  def test_map_file_names
    file_names = [
      './lib/autotest.rb',
      './test/test_autotest.rb',
    ]

    expected = [
      [['test/test_autotest.rb']],
      [['test/test_autotest.rb']],
    ]

    file_names.each_with_index do |name, i|
      assert_equal expected[i], @at.map_file_names([name]), "test #{i}, #{name}"
    end
  end

  def test_retest_failed_modified
    failed = [['test_route', 'PhotoTest']]
    tests = [@photo_test_file]

    @at.system_responses = [true]

    util_touch @photo_test_file

    out, err = util_capture do
      @at.retest_failed failed, tests
    end

    out = out.split $/

    assert_equal "# Rerunning failures: #{@photo_test_file}", out.shift
    assert_equal "+ ruby -Ilib:test -S testrb -n test_route #{@photo_test_file}", out.shift

    assert_equal true, @at.system_responses.empty?
  end

  def test_updated_eh
    assert_equal true,  @at.updated?(@photo_test_file), 'Not in @files'
    assert_equal false, @at.updated?(@photo_test_file), 'In @files'
    @at.files[@photo_test_file] = Time.at 1
    util_touch @photo_test_file
    assert_equal true,  @at.updated?(@photo_test_file), 'Touched'
  end

  def test_updated_files
    Dir.chdir 'test/data/plain' do
      @at.updated_files
    end

    expected = {
      './photo_test.rb' => File.stat(@photo_test_file).mtime,
      './route_test.rb' => File.stat(@route_test_file).mtime,
      './user_test.rb'  => File.stat(@user_test_file).mtime,
    }

    assert_equal expected, @at.files

    util_touch @photo_test_file

    assert_not_equal expected['./photo_test.rb'], @at.files
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

  def util_touch(file, time = nil)
    timestamp = time ? " -t #{time.strftime '%Y%m%d%H%M.%S'}" : nil
    cmd = "touch #{timestamp} #{file}"
    system cmd
  end

end

