= ZenTest

* http://www.zenspider.com/ZSS/Products/ZenTest/
* support@zenspider.com

== DESCRIPTION

ZenTest provides 4 different tools: zentest, unit_diff, autotest, and
multiruby.

ZenTest scans your target and unit-test code and writes your missing
code based on simple naming rules, enabling XP at a much quicker
pace. ZenTest only works with Ruby and Test::Unit.

unit_diff is a command-line filter to diff expected results from
actual results and allow you to quickly see exactly what is wrong.

autotest is a continous testing facility meant to be used during
development. As soon as you save a file, autotest will run the
corresponding dependent tests.

multiruby runs anything you want on multiple versions of ruby. Great
for compatibility checking!

There are two strategies intended for ZenTest: test conformance
auditing and rapid XP.

For auditing, ZenTest provides an excellent means of finding methods
that have slipped through the testing process. I've run it against my
own software and found I missed a lot in a well tested
package. Writing those tests found 4 bugs I had no idea existed.

ZenTest can also be used to evaluate generated code and execute your
tests, allowing for very rapid development of both tests and
implementation.

== FEATURES/PROBLEMS

* Scans your ruby code and tests and generates missing methods for you.
* Includes a very helpful filter for Test::Unit output called unit_diff.
* Continually and intelligently test only those files you change with autotest.
* Test against multiple versions with multiruby.
- Not the best doco in the world (my fault)
* Includes a LinuxJournal article on testing with ZenTest written by Pat Eyler.
* See also: http://blog.zenspider.com/archives/zentest/

== SYNOPSYS

  ZenTest MyProject.rb TestMyProject.rb > missing.rb

  ./TestMyProject.rb | unit_diff

  autotest

  multiruby ./TestMyProject.rb

== RULES

ZenTest uses the following rules to figure out what code should be
generated:

* Definition:
  * CUT = Class Under Test
  * TC = Test Class (for CUT)
* TC's name is the same as CUT w/ "Test" prepended at every scope level.
  * Example: TestA::TestB vs A::B.
* CUT method names are used in CT, with "test_" prependend and optional "_ext" extensions for differentiating test case edge boundaries.
  * Example:
    * A::B#blah
    * TestA::TestB#test_blah_normal
    * TestA::TestB#test_blah_missing_file
* All naming conventions are bidirectional with the exception of test extensions.

== METHOD MAPPING

Method names are mapped bidirectionally in the following way:

  method	test_method
  method?	test_method_eh		(too much exposure to Canadians :)
  method!	test_method_bang
  method=	test_method_equals
  []		test_index
  *		test_times
  ==		test_equals2
  ===		test_equals3

Further, any of the test methods should be able to have arbitrary
extensions put on the name to distinguish edge cases:

  method	test_method
  method	test_method_simple
  method	test_method_no_network

To allow for unmapped test methods (ie, non-unit tests), name them:

  test_integration_.*

== REQUIREMENTS

* Ruby 1.6+
* Test::Unit
* Rake or rubygems for install/uninstall

== INSTALL

* make test
* sudo make install

== LICENSE

(The MIT License)

Copyright (c) 2001-2006 Ryan Davis, Eric Hodel, Zen Spider Software

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

