##
# Extra assertions for Test::Unit

module Test::Unit::Assertions

  ##
  # Asserts that +boolean+ is not false or nil.

  def deny(boolean, message = nil)
    _wrap_assertion do
      assert_block(build_message(message, "<?> is not false or nil.", boolean)) { not boolean }
    end
  end

  ##
  # Alias for assert_not_equal

  alias deny_equal assert_not_equal

  ##
  # Asserts that +obj+ responds to #empty? and #empty? returns true.

  def assert_empty(obj)
    assert_respond_to obj, :empty?
    assert_block "#{obj.inspect} expected to be empty." do obj.empty? end
  end

  ##
  # Asserts that +obj+ responds to #empty? and #empty? returns false.

  def deny_empty(obj)
    assert_respond_to obj, :empty?
    assert_block "#{obj.inspect} expected to have stuff." do !obj.empty? end
  end

  ##
  # Like assert_in_delta but better dealing with errors proportional
  # to the sizes of +a+ and +b+.

  def assert_in_epsilon(a, b, epsilon, message="")
    return true if a == b
    error = ((a - b) / (b.abs > a.abs) ? b : a).abs
    error <= epsilon
  end

  ##
  # Asserts that +obj+ is not nil.

  alias deny_nil assert_not_nil

  ##
  # Asserts that +obj+ responds to #include? and that obj includes +item+.

  def assert_include(item, obj, message = nil)
    assert_respond_to obj, :include?
    message ||= "#{obj.inspect} does not include #{item.inspect}."
    assert_block message do obj.include? item end
  end

  alias assert_includes assert_include

  ##
  # Asserts that +obj+ responds to #include? and that obj does not include
  # +item+.

  def deny_include(item, obj, message = nil)
    assert_respond_to obj, :include?
    message ||= "#{obj.inspect} includes #{item.inspect}."
    assert_block message do !obj.include? item end
  end

  alias deny_includes deny_include

  ##
  # Captures $stdout and $stderr to StringIO objects and returns them.
  # Restores $stdout and $stderr when done.
  #
  # Usage:
  #   def test_puts
  #     out, err = capture do
  #       puts 'hi'
  #       STDERR.puts 'bye!'
  #     end
  #     assert_equal "hi\n", out.string
  #     assert_equal "bye!\n", err.string
  #   end

  def util_capture
    require 'stringio'
    orig_stdout = $stdout.dup
    orig_stderr = $stderr.dup
    captured_stdout = StringIO.new
    captured_stderr = StringIO.new
    $stdout = captured_stdout
    $stderr = captured_stderr
    yield
    captured_stdout.rewind
    captured_stderr.rewind
    return captured_stdout, captured_stderr
  ensure
    $stdout = orig_stdout
    $stderr = orig_stderr
  end

end

class Object # :nodoc:
  unless respond_to? :path2class then
    def path2class(path) # :nodoc:
      path.split('::').inject(Object) { |k,n| k.const_get n }
    end
  end
end

