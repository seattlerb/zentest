ZenTest
    http://www.zenspider.com/ZSS/Products/ZenTest/
    support@zenspider.com

** DESCRIPTION:
  
ZenTest scans your target and unit-test code and writes your missing
code based on simple naming rules, enabling XP at a much quicker
pace. ZenTest only works with Ruby and Test::Unit.

** FEATURES/PROBLEMS:
  
+ Scans your ruby code and tests and generates missing methods for you.

** SYNOPSYS:

  ZenTest.rb MyProject.rb TestMyProject.rb > missing.rb
  # edit missing.rb and merge appropriate parts into the above files.

** RULES:

ZenTest uses the following rules to figure out what code should be
generated:

+ Definition: CUT = class under test, TC = Test Class (for CUT)
+ TC's name is the same as CUT w/ "Test" prepended at every scope level.
	+ Example: TestA::TestB vs A::B.
+ CUT method names are used in CT, with "test_" prependend and optional "_ext" extensions for differentiating test case edge boundaries.
	+ Example: A::B#blah vs TestA::TestB#test_blah_missing_file
+ All naming conventions are bidirectional with the exception of test extensions.

** REQUIREMENTS:

+ Ruby 1.6+
+ Test::Unit

** INSTALL:

+ No install instructions yet. TODO

** LICENSE:

(The MIT License)

Copyright (c) 2001-2002 Ryan Davis, Zen Spider Software

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
