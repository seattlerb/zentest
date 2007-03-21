# -*- mode -*-

module Autotest::Growl
  def self.growl title, msg, pri=0
    title += " in #{Dir.pwd}"
    msg += " at #{Time.now}"
    system "growlnotify -n autotest --image /Applications/Mail.app/Contents/Resources/Caution.tiff -p #{pri} -m #{msg.inspect} #{title}"
  end

  Autotest.add_hook :run do  |at|
    growl "autotest running", "Started"
  end

  Autotest.add_hook :red do |at|
    growl "Tests Failed", "#{at.files_to_test.size} tests failed", 2
  end

  Autotest.add_hook :green do |at|
    growl "Tests Passed", "Tests passed", -2 if at.tainted
  end

  Autotest.add_hook :all_good do |at|
    growl "Tests Passed", "All tests passed", -2 if at.tainted
  end
end
