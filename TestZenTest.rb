#!/usr/local/bin/ruby -w

require 'test/unit'

$TESTING = true

# I do this so I can still run ZenTest against the tests and itself...
if __FILE__ == $0 then
  puts "Requiring ZenTest"
  require 'ZenTest'
end

# These are just classes set up for quick testing.

class Cls1				# ZenTest SKIP
  def meth1; end
end

class TestCls1				# ZenTest SKIP
  def test_meth1
  end

  def test_meth2
    assert(true, "something")
  end
end

class SuperDuper			# ZenTest SKIP
  def inherited
  end
  def overridden
  end
end

class LowlyOne < SuperDuper		# ZenTest SKIP
  def overridden
  end
  def extended
  end
end

class TestZenTest < Test::Unit::TestCase

  def setup
    @tester = ZenTest.new()
  end

  def test_initialize
    assert_not_nil(@tester, "Tester must be initialized")
  end

  ############################################################
  # Accessors & Adders:

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

  def util_simple_setup
    @tester.klasses = {"Something" => { "method1" => true } }
    @tester.test_klasses = {"TestSomething" => { "test_method2" => true } }
  end

  def test_analyze_simple
    self.util_simple_setup

    @tester.analyze
    missing = @tester.missing_methods
    assert_equal({"Something" => { "method2" => true },
		   "TestSomething" => { "test_method1" => true } },
		 missing)
  end

  def test_generate_code_simple
    self.util_simple_setup
    
    @tester.analyze
    str = @tester.generate_code.join("\n")
    exp = "\nrequire 'test/unit'\n\nclass Something\n  def method2\n    raise NotImplementedError, 'Need to write method2'\n  end\nend\n\nclass TestSomething < Test::Unit::TestCase\n  def test_method1\n    raise NotImplementedError, 'Need to write test_method1'\n  end\nend\n\n# Number of errors detected: 2\n"

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
    str = @tester.result
    exp = "\nrequire 'test/unit'\n\nclass Something\n  def method2\n    raise NotImplementedError, 'Need to write method2'\n  end\nend\n\nclass TestSomething < Test::Unit::TestCase\n  def test_method1\n    raise NotImplementedError, 'Need to write test_method1'\n  end\nend\n\n# Number of errors detected: 2\n"

    assert_equal(exp, str)
  end

  def test_load_file
    # HACK raise NotImplementedError, 'Need to write test_load_file'
  end

  def test_scan_files
    # HACK raise NotImplementedError, 'Need to write test_scan_files'
  end

end

