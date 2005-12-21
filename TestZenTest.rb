#!/usr/local/bin/ruby -w

require 'test/unit' unless defined? $ZENTEST and $ZENTEST

$TESTING = true

# I do this so I can still run ZenTest against the tests and itself...
if __FILE__ == $0 then
  puts "Requiring ZenTest"
  require 'ZenTest'
end

# These are just classes set up for quick testing.
# TODO: need to test a compound class name Mod::Cls

class Cls1				# ZenTest SKIP
  def meth1; end
  def self.meth2; end
end

class TestCls1				# ZenTest SKIP
  def setup; end
  def teardown; end
  def test_meth1; end
  def test_meth2; assert(true, "something"); end
end

class SuperDuper			# ZenTest SKIP
  def inherited; end
  def overridden; end
end

class LowlyOne < SuperDuper		# ZenTest SKIP
  def overridden; end
  def extended; end
end

class TestZenTest < Test::Unit::TestCase

  def setup
    @tester = ZenTest.new()
  end

  ############################################################
  # Utility Methods

  def util_simple_setup
    @tester.klasses = {
      "Something" =>
        {
        "method1" => true,
        "method1!" => true,
        "method1=" => true,
        "method1?" => true,
        "attrib" => true,
        "attrib=" => true,
        "equal?" => true,
        "self.method3" => true,
        "self.[]" => true,
      },
    }
    @tester.test_klasses = {
      "TestSomething" =>
        {
        "test_class_method4" => true,
        "test_method2" => true,
        "setup" => true,
        "teardown" => true,
        "test_class_index" => true,
      },
    }
    @tester.inherited_methods = @tester.test_klasses.merge(@tester.klasses)
    @generated_code = "
require 'test/unit' unless defined? $ZENTEST and $ZENTEST

class Something
  def self.method4(*args)
    raise NotImplementedError, 'Need to write self.method4'
  end

  def method2(*args)
    raise NotImplementedError, 'Need to write method2'
  end
end

class TestSomething < Test::Unit::TestCase
  def test_class_method3
    raise NotImplementedError, 'Need to write test_class_method3'
  end

  def test_attrib
    raise NotImplementedError, 'Need to write test_attrib'
  end

  def test_attrib_equals
    raise NotImplementedError, 'Need to write test_attrib_equals'
  end

  def test_equal_eh
    raise NotImplementedError, 'Need to write test_equal_eh'
  end

  def test_method1
    raise NotImplementedError, 'Need to write test_method1'
  end

  def test_method1_bang
    raise NotImplementedError, 'Need to write test_method1_bang'
  end

  def test_method1_eh
    raise NotImplementedError, 'Need to write test_method1_eh'
  end

  def test_method1_equals
    raise NotImplementedError, 'Need to write test_method1_equals'
  end
end

# Number of errors detected: 10
"
  end

  ############################################################
  # Accessors & Adders:

  def test_initialize
    assert_not_nil(@tester, "Tester must be initialized")
    # TODO: should do more at this stage
  end

  ############################################################
  # Converters and Testers:

  def test_is_test_class
    # classes
    assert(@tester.is_test_class(TestCls1),
	   "All test classes must start with Test")
    assert(!@tester.is_test_class(Cls1),
	   "Classes not starting with Test must not be test classes")
    # strings
    assert(@tester.is_test_class("TestCls1"),
	   "All test classes must start with Test")
    assert(@tester.is_test_class("TestMod::TestCls1"),
	   "All test modules must start with test as well")
    assert(!@tester.is_test_class("Cls1"),
	   "Classes not starting with Test must not be test classes")
    assert(!@tester.is_test_class("NotTestMod::TestCls1"),
	   "Modules not starting with Test must not be test classes")
    assert(!@tester.is_test_class("NotTestMod::NotTestCls1"),
	   "All names must start with Test to be test classes")
  end

  def test_is_test_class_reversed
    old = $r
    $r = true
    assert(@tester.is_test_class("Cls1Test"),
           "Reversed: All test classes must end with Test")
    assert(@tester.is_test_class("ModTest::Cls1Test"),
           "Reversed: All test classes must end with Test")
    assert(!@tester.is_test_class("TestMod::TestCls1"),
           "Reversed: All test classes must end with Test")
    $r = old
  end

  def test_convert_class_name

    assert_equal('Cls1', @tester.convert_class_name(TestCls1))
    assert_equal('TestCls1', @tester.convert_class_name(Cls1))

    assert_equal('Cls1', @tester.convert_class_name('TestCls1'))
    assert_equal('TestCls1', @tester.convert_class_name('Cls1'))

    assert_equal('TestModule::TestCls1',
		 @tester.convert_class_name('Module::Cls1'))
    assert_equal('Module::Cls1',
		 @tester.convert_class_name('TestModule::TestCls1'))
  end

  def test_convert_class_name_reversed
    old = $r
    $r = true

    assert_equal('Cls1', @tester.convert_class_name("Cls1Test"))
    assert_equal('Cls1Test', @tester.convert_class_name(Cls1))

    assert_equal('Cls1', @tester.convert_class_name('Cls1Test'))
    assert_equal('Cls1Test', @tester.convert_class_name('Cls1'))

    assert_equal('ModuleTest::Cls1Test',
		 @tester.convert_class_name('Module::Cls1'))
    assert_equal('Module::Cls1',
		 @tester.convert_class_name('ModuleTest::Cls1Test'))
    $r = old
  end

  ############################################################
  # Missing Classes and Methods:

  def test_missing_methods_empty
    missing = @tester.missing_methods
    assert_equal({}, missing)
  end

  def test_add_missing_method_normal
    @tester.add_missing_method("SomeClass", "some_method")
    missing = @tester.missing_methods
    assert_equal({"SomeClass" => { "some_method" => true } }, missing)
  end

  def test_add_missing_method_duplicates
    @tester.add_missing_method("SomeClass", "some_method")
    @tester.add_missing_method("SomeClass", "some_method")
    @tester.add_missing_method("SomeClass", "some_method")
    missing = @tester.missing_methods
    assert_equal({"SomeClass" => { "some_method" => true } }, missing)
  end

  def test_analyze_simple
    self.util_simple_setup

    @tester.analyze
    missing = @tester.missing_methods
    expected = {
      "Something" => {
        "method2" => true,
        "self.method4" => true,
      },
      "TestSomething" => {
        "test_class_method3" => true,
        "test_attrib" => true,
        "test_attrib_equals" => true,
        "test_equal_eh" => true,
        "test_method1" => true,
        "test_method1_eh"=>true,
        "test_method1_bang"=>true,
        "test_method1_equals"=>true,
      }
    }
    assert_equal(expected, missing)
  end

  def test_generate_code_simple
    self.util_simple_setup
    
    @tester.analyze
    str = @tester.generate_code[1..-1].join("\n")
    exp = @generated_code

    assert_equal(exp, str)
  end

  def test_get_class_good
    assert_equal(Object, @tester.get_class("Object"))
  end

  def test_get_class_bad
    assert_nil(@tester.get_class("ZZZObject"))
  end

  def test_get_inherited_methods_for_subclass
    expect = { "inherited" => true, "overridden" => true }
    result = @tester.get_inherited_methods_for("LowlyOne", false)

    assert_equal(expect, result)
  end

  def test_get_inherited_methods_for_subclass_full
    expect = LowlyOne.superclass.instance_methods(true)
    result = @tester.get_inherited_methods_for("LowlyOne", true)

    assert_equal(expect.sort, result.keys.sort)
  end

  def test_get_inherited_methods_for_superclass
    expect = { }
    result = @tester.get_inherited_methods_for("SuperDuper", false)

    assert_equal(expect.keys.sort, result.keys.sort)
  end

  def test_get_inherited_methods_for_superclass_full
    expect = SuperDuper.superclass.instance_methods(true)
    result = @tester.get_inherited_methods_for("SuperDuper", true)

    assert_equal(expect.sort, result.keys.sort)
  end

  def test_get_methods_for_subclass
    expect = { "overridden" => true, "extended" => true }
    result = @tester.get_methods_for("LowlyOne")

    assert_equal(expect, result)
  end

  def test_get_methods_for_superclass
    expect = { "overridden" => true, "inherited" => true }
    result = @tester.get_methods_for("SuperDuper")

    assert_equal(expect, result)
  end

  def test_result
    self.util_simple_setup
    
    @tester.analyze
    @tester.generate_code
    str = @tester.result.split($/, 2).last
    exp = @generated_code

    assert_equal(exp, str)
  end

  def test_load_file
    # HACK raise NotImplementedError, 'Need to write test_load_file'
  end

  def test_scan_files
    # HACK raise NotImplementedError, 'Need to write test_scan_files'
  end

  def test_process_class
    assert_equal({}, @tester.klasses)
    assert_equal({}, @tester.test_klasses)
    assert_equal(nil, @tester.inherited_methods["SuperDuper"])
    @tester.process_class("SuperDuper")
    assert_equal({"SuperDuper"=>{"inherited"=>true, "overridden"=>true}},
                 @tester.klasses)
    assert_equal({}, @tester.test_klasses)
    assert_equal({}, @tester.inherited_methods["SuperDuper"])
  end

  def test_normal_to_test
    self.util_simple_setup
    assert_equal("test_method1",        @tester.normal_to_test("method1"))
    assert_equal("test_method1_bang",   @tester.normal_to_test("method1!"))
    assert_equal("test_method1_eh",     @tester.normal_to_test("method1?"))
    assert_equal("test_method1_equals", @tester.normal_to_test("method1="))
  end

  def test_normal_to_test_cls
    self.util_simple_setup
    assert_equal("test_class_method1",        @tester.normal_to_test("self.method1"))
    assert_equal("test_class_method1_bang",   @tester.normal_to_test("self.method1!"))
    assert_equal("test_class_method1_eh",     @tester.normal_to_test("self.method1?"))
    assert_equal("test_class_method1_equals", @tester.normal_to_test("self.method1="))
  end

  def test_normal_to_test_operators
    self.util_simple_setup
    assert_equal("test_and",     @tester.normal_to_test("&"))
    assert_equal("test_bang",    @tester.normal_to_test("!"))
    assert_equal("test_carat",   @tester.normal_to_test("^"))
    assert_equal("test_div",     @tester.normal_to_test("/"))
    assert_equal("test_equalstilde", @tester.normal_to_test("=~"))
    assert_equal("test_minus",   @tester.normal_to_test("-"))
    assert_equal("test_or",      @tester.normal_to_test("|"))
    assert_equal("test_percent", @tester.normal_to_test("%"))
    assert_equal("test_plus",    @tester.normal_to_test("+"))
    assert_equal("test_tilde",   @tester.normal_to_test("~"))
  end

  def test_normal_to_test_overlap
    self.util_simple_setup
    assert_equal("test_equals2",       @tester.normal_to_test("=="))
    assert_equal("test_equals3",       @tester.normal_to_test("==="))
    assert_equal("test_ge",            @tester.normal_to_test(">="))
    assert_equal("test_gt",            @tester.normal_to_test(">"))
    assert_equal("test_gt2",           @tester.normal_to_test(">>"))
    assert_equal("test_index",         @tester.normal_to_test("[]"))
    assert_equal("test_index_equals",  @tester.normal_to_test("[]="))
    assert_equal("test_lt",            @tester.normal_to_test("<"))
    assert_equal("test_lt2",           @tester.normal_to_test("<\<"))
    assert_equal("test_lte",           @tester.normal_to_test("<="))
    assert_equal("test_method",        @tester.normal_to_test("method"))
    assert_equal("test_method_equals", @tester.normal_to_test("method="))
    assert_equal("test_spaceship",     @tester.normal_to_test("<=>"))
    assert_equal("test_times",         @tester.normal_to_test("*"))
    assert_equal("test_times2",        @tester.normal_to_test("**"))
    assert_equal("test_unary_minus",   @tester.normal_to_test("@-"))
    assert_equal("test_unary_plus",    @tester.normal_to_test("@+"))
    assert_equal("test_class_index",   @tester.normal_to_test("self.[]"))
  end

  def test_test_to_normal
    self.util_simple_setup
    assert_equal("method1!", @tester.test_to_normal("test_method1_bang", "Something"))
    assert_equal("method1",  @tester.test_to_normal("test_method1", "Something"))
    assert_equal("method1=", @tester.test_to_normal("test_method1_equals", "Something"))
    assert_equal("method1?", @tester.test_to_normal("test_method1_eh", "Something"))
  end

  def test_test_to_normal_cls
    self.util_simple_setup
    assert_equal("self.method1",  @tester.test_to_normal("test_class_method1"))
    assert_equal("self.method1!", @tester.test_to_normal("test_class_method1_bang"))
    assert_equal("self.method1?", @tester.test_to_normal("test_class_method1_eh"))
    assert_equal("self.method1=", @tester.test_to_normal("test_class_method1_equals"))
    assert_equal("self.[]", @tester.test_to_normal("test_class_index"))
  end

  def test_test_to_normal_extended
    self.util_simple_setup
    assert_equal("equal?",  @tester.test_to_normal("test_equal_eh_extension", "Something"))
    assert_equal("equal?",  @tester.test_to_normal("test_equal_eh_extension_again", "Something"))
    assert_equal("method1", @tester.test_to_normal("test_method1_extension", "Something"))
    assert_equal("method1", @tester.test_to_normal("test_method1_extension_again", "Something"))
  end

  def test_test_to_normal_mapped
    self.util_simple_setup
    assert_equal("*",   @tester.test_to_normal("test_times"))
    assert_equal("*",   @tester.test_to_normal("test_times_ext"))
    assert_equal("==",  @tester.test_to_normal("test_equals2"))
    assert_equal("==",  @tester.test_to_normal("test_equals2_ext"))
    assert_equal("===", @tester.test_to_normal("test_equals3"))
    assert_equal("===", @tester.test_to_normal("test_equals3_ext"))
    assert_equal("[]",  @tester.test_to_normal("test_index"))
    assert_equal("[]",  @tester.test_to_normal("test_index_ext"))
    assert_equal("[]=", @tester.test_to_normal("test_index_equals"))
    assert_equal("[]=", @tester.test_to_normal("test_index_equals_ext"))
  end

  def test_test_to_normal_operators
    self.util_simple_setup
    assert_equal("&",  @tester.test_to_normal("test_and"))
    assert_equal("!",  @tester.test_to_normal("test_bang"))
    assert_equal("^",  @tester.test_to_normal("test_carat"))
    assert_equal("/",  @tester.test_to_normal("test_div"))
    assert_equal("=~", @tester.test_to_normal("test_equalstilde"))
    assert_equal("-",  @tester.test_to_normal("test_minus"))
    assert_equal("|",  @tester.test_to_normal("test_or"))
    assert_equal("%",  @tester.test_to_normal("test_percent"))
    assert_equal("+",  @tester.test_to_normal("test_plus"))
    assert_equal("~",  @tester.test_to_normal("test_tilde"))
  end

  def test_test_to_normal_overlap
    self.util_simple_setup
    assert_equal("==",  @tester.test_to_normal("test_equals2"))
    assert_equal("===", @tester.test_to_normal("test_equals3"))
    assert_equal(">=",  @tester.test_to_normal("test_ge"))
    assert_equal(">",   @tester.test_to_normal("test_gt"))
    assert_equal(">>",  @tester.test_to_normal("test_gt2"))
    assert_equal("[]",  @tester.test_to_normal("test_index"))
    assert_equal("[]=", @tester.test_to_normal("test_index_equals"))
    assert_equal("<",   @tester.test_to_normal("test_lt"))
    assert_equal("<\<", @tester.test_to_normal("test_lt2"))
    assert_equal("<=",  @tester.test_to_normal("test_lte"))
    assert_equal("<=>", @tester.test_to_normal("test_spaceship"))
    assert_equal("*",   @tester.test_to_normal("test_times"))
    assert_equal("**",  @tester.test_to_normal("test_times2"))
    assert_equal("@-",  @tester.test_to_normal("test_unary_minus"))
    assert_equal("@+",  @tester.test_to_normal("test_unary_plus"))
  end

  def test_klasses_equals
    self.util_simple_setup
    assert_equal({"Something"=> {
                     "self.method3"=>true,
                     "equal?"=>true,
                     "attrib="=>true,
                     "self.[]"=>true,
                     "method1"=>true,
                     "method1="=>true,
                     "method1?"=>true,
                     "method1!"=>true,
                     "method1"=>true,
                     "attrib"=>true}}, @tester.klasses)
    @tester.klasses= {"whoopie" => {}}
    assert_equal({"whoopie"=> {}}, @tester.klasses)
  end

  Dir['testcase*.rb'].each do |rb_file|
    basename = File.basename(rb_file, '.rb')
    
    define_method("test_#{basename}".intern) do
      expected = File.read(basename + '.result')
      result = ZenTest.fix(rb_file)
      result = result.split($/)
      result = result[1..-1]
      result = result[1..-1] if $DEBUG
      result = result.join($/)
      assert_equal expected.strip, result
    end
  end
end

class TestUnitDiff < Test::Unit::TestCase
  def setup
    @diff = UnitDiff.new
  end

  def test_input
    input = "Loaded suite ./blah\nStarted\nFF\nFinished in 0.035332 seconds.\n\n  1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n<\"line1\\nline2\\nline3\\n\"> expected but was\n<\"line4\\nline5\\nline6\\n\">.\n\n  2) Failure:\ntest_test2(TestBlah) [./blah.rb:29]:\n<\"line1\"> expected but was\n<\"line2\\nline3\\n\\n\">.\n\n2 tests, 2 assertions, 2 failures, 0 errors\n"

    # TODO: I think I'd like a separate footer array as well
    expected = [
                ["Loaded suite ./blah\n", "Started\n", "FF\n", "Finished in 0.035332 seconds.\n"],
                [
                 ["  1) Failure:\n", "test_test1(TestBlah) [./blah.rb:25]:\n", "<\"line1\\nline2\\nline3\\n\"> expected but was\n", "<\"line4\\nline5\\nline6\\n\">.\n"],
                 ["  2) Failure:\n", "test_test2(TestBlah) [./blah.rb:29]:\n", "<\"line1\"> expected but was\n", "<\"line2\\nline3\\n\\n\">.\n"],
                 ],
                ["\n", "2 tests, 2 assertions, 2 failures, 0 errors\n"]
               ]

    assert_equal expected, @diff.input(input)
  end

  def test_parse_diff1
    input = ["  1) Failure:\n",
             "test_test1(TestBlah) [./blah.rb:25]:\n",
             "<\"line1\\nline2\\nline3\\n\"> expected but was\n",
             "<\"line4\\nline5\\nline6\\n\">.\n"
            ]

    expected = [["  1) Failure:\n", "test_test1(TestBlah) [./blah.rb:25]:\n"], ["line1\\nline2\\nline3\\n"], ["line4\\nline5\\nline6\\n"]]

    assert_equal expected, @diff.parse_diff(input)
  end

  def test_parse_diff2
    input = ["  2) Failure:\n",
             "test_test2(TestBlah) [./blah.rb:29]:\n",
             "<\"line1\"> expected but was\n",
             "<\"line2\\nline3\\n\\n\">.\n"
            ]

    expected = [["  2) Failure:\n",
                 "test_test2(TestBlah) [./blah.rb:29]:\n"],
                ["line1"],
                ["line2\\nline3\\n\\n"]
               ]

    assert_equal expected, @diff.parse_diff(input)
  end

  def test_unit_diff1
    input = "Loaded suite ./blah\nStarted\nF\nFinished in 0.035332 seconds.\n\n  1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n<\"line1\\nline2\\nline3\\n\"> expected but was\n<\"line4\\nline5\\nline6\\n\">.\n\n1 tests, 1 assertions, 1 failures, 0 errors\n"

    expected = "1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n1,3c1,3\n< line1\n< line2\n< line3\n---\n> line4\n> line5\n> line6\n\n1 tests, 1 assertions, 1 failures, 0 errors"

    assert_equal expected, @diff.unit_diff(input)
  end

  def test_unit_diff2
    input = "Loaded suite ./blah\nStarted\nFF\nFinished in 0.035332 seconds.\n\n  1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n<\"line1\\nline2\\nline3\\n\"> expected but was\n<\"line4\\nline5\\nline6\\n\">.\n\n  2) Failure:\ntest_test2(TestBlah) [./blah.rb:29]:\n<\"line1\"> expected but was\n<\"line2\\nline3\\n\\n\">.\n\n2 tests, 2 assertions, 2 failures, 0 errors\n"

    expected = "1) Failure:\ntest_test1(TestBlah) [./blah.rb:25]:\n1,3c1,3\n< line1\n< line2\n< line3\n---\n> line4\n> line5\n> line6\n\n2) Failure:\ntest_test2(TestBlah) [./blah.rb:29]:\n1c1,3\n< line1\n\\ No newline at end of file\n---\n> line2\n> line3\n>\n\n2 tests, 2 assertions, 2 failures, 0 errors"

    assert_equal expected, @diff.unit_diff(input)
  end
end
