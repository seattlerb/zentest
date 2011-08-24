= ZenTest

home :: https://github.com/seattlerb/zentest
rdoc :: http://zentest.rubyforge.org/ZenTest

== DESCRIPTION

ZenTest provides 4 different tools: zentest, unit_diff, autotest, and
multiruby.

ZenTest scans your target and unit-test code and writes your missing
code based on simple naming rules, enabling XP at a much quicker
pace. ZenTest only works with Ruby and Test::Unit. Nobody uses this
tool anymore but it is the package namesake, so it stays.

unit_diff is a command-line filter to diff expected results from
actual results and allow you to quickly see exactly what is wrong.
Do note that minitest 2.2+ provides an enhanced assert_equal obviating
the need for unit_diff

autotest is a continous testing facility meant to be used during
development. As soon as you save a file, autotest will run the
corresponding dependent tests.

multiruby runs anything you want on multiple versions of ruby. Great
for compatibility checking! Use multiruby_setup to manage your
installed versions.

== FEATURES

* Scans your ruby code and tests and generates missing methods for you.
* Includes a very helpful filter for Test/Spec output called unit_diff.
* Continually and intelligently test only those files you change with autotest.
* Test against multiple versions with multiruby.
* Includes a LinuxJournal article on testing with ZenTest written by Pat Eyler.
* See also: http://blog.zenspider.com/archives/zentest/
* See also: http://blog.segment7.net/articles/category/zentest

== STRATEGERY

There are two strategeries intended for ZenTest: test conformance
auditing and rapid XP.

For auditing, ZenTest provides an excellent means of finding methods
that have slipped through the testing process. I've run it against my
own software and found I missed a lot in a well tested
package. Writing those tests found 4 bugs I had no idea existed.

ZenTest can also be used to evaluate generated code and execute your
tests, allowing for very rapid development of both tests and
implementation.

== AUTOTEST TIPS

Setting up your project with a custom setup is easily done by creating
a ".autotest" file in your project. Here is an example of adding some
plugins, using minitest as your test library, and running rcov on full
passes:

    require 'autotest/restart'

    Autotest.add_hook :initialize do |at|
      at.testlib = "minitest/autorun"
    end

    Autotest.add_hook :all_good do |at|
      system "rake rcov_info"
    end if ENV['RCOV']

Do note, since minitest ships with ruby19, if you want to use the
latest minitest gem you need to ensure that the gem activation occurs!
To do this, add the gem activation and the proper require to a
separate file (like ".minitest.rb" or even a test helper if you have
one) and use that for your testlib instead:

.minitest.rb:

    gem "minitest"
    require "minitest/autorun"

.autotest:

    Autotest.add_hook :initialize do |at|
      at.testlib = ".minitest"
    end

== SYNOPSYS

  ZenTest MyProject.rb TestMyProject.rb > missing.rb

  ./TestMyProject.rb | unit_diff

  autotest

  multiruby_setup mri:svn:current
  multiruby ./TestMyProject.rb

== Windows and Color

Read this: http://blog.mmediasys.com/2010/11/24/we-all-love-colors/

== REQUIREMENTS

* Ruby 1.8+, JRuby 1.1.2+, or rubinius
* A test/spec framework of your choice.
* Hoe (development)
* rubygems
* diff.exe on windows. Use http://gnuwin32.sourceforge.net/packages.html

== INSTALL

* sudo gem install ZenTest

== LICENSE

(The MIT License)

Copyright (c) Ryan Davis, Eric Hodel, seattle.rb

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

