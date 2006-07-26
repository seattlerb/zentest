# -*- ruby -*-

module AutoGrowl
  def self.growl title, msg, pri=0
    system "growlnotify -n autotest --image /Applications/Mail.app/Contents/Resources/Caution.tiff -p #{pri} -m #{msg.inspect} #{title}"
  end

  Autotest.add_hook :run do  |at|
    growl "Run", "Run" unless $TESTING
  end

  Autotest.add_hook :red do |at|
    growl "Tests Failed", "#{at.files_to_test.size} tests passed", 2
  end

  Autotest.add_hook :green do |at|
    growl "Tests Passed", "All tests passed", -2 if at.tainted 
  end

  Autotest.add_hook :init do |at|
    growl "autotest", "autotest was started" unless $TESTING
  end

  Autotest.add_hook :interrupt do |at|
    growl "autotest", "autotest was reset" unless $TESTING
  end

  Autotest.add_hook :quit do |at|
    growl "autotest", "autotest is exiting" unless $TESTING
  end

  Autotest.add_hook :all do |at|_hook
    growl "autotest", "Tests have fully passed", -2 unless $TESTING
  end
end

module HtmlConsole
  MAX = 30
  STATUS = {}
  PATH = File.expand_path("~/Sites/autotest.html")

  def self.update
    STATUS.delete STATUS.keys.sort.last if STATUS.size > MAX
    File.open(PATH, "w") do |f|
      f.puts "<title>Autotest Status</title>"
      STATUS.sort.reverse.each do |t,s|
        if s > 0 then
          f.puts "<p style=\"color:red\">#{t}: #{s}"
        else
          f.puts "<p style=\"color:green\">#{t}: #{s}"
        end
      end
    end
  end

  Autotest.add_hook :red do |at|
    STATUS[Time.now] = at.files_to_test.size
    update
  end

  Autotest.add_hook :green do |at|
    STATUS[Time.now] = 0
    update
  end
end

