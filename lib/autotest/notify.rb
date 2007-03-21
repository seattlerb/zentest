# libnotify plugin for autotest

begin require 'rubygems'; rescue LoadError; end
require 'libnotify'

module Autotest::LibNotify

  LibNotify.init("autotest")

  def self.notify title, msg, ico = :info
    LibNotify::Notification.new(title, msg, "gtk-#{ico}", nil).show
  end

  Autotest.add_hook :red do |at|
    failed_tests = at.files_to_test.inject(0){ |s,a| k,v = a;  s + v.size}
    notify "Tests Failed", "#{failed_tests} tests failed", :no
  end

  Autotest.add_hook :green do |at|
    notify "Tests Passed", "All tests passed", :yes
  end

  Autotest.add_hook :run do |at|
    notify "autotest", "autotest was started" unless $TESTING
  end

  Autotest.add_hook :interrupt do |at|
    notify "autotest", "autotest was reset" unless $TESTING
  end

  Autotest.add_hook :quit do |at|
    notify "autotest", "autotest is exiting" unless $TESTING
  end

  Autotest.add_hook :all do |at|_hook
    notify "autotest", "Tests have fully passed", :yes unless $TESTING
  end
end
